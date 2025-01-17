import 'package:queueing_simulator/processes.dart';
import 'package:yaml/yaml.dart';

/// Queueing system simulator.
class Simulator {
  final bool verbose;
  final List<Process> processes = [];
  final List<Event> eventQueue = [];
  int currentTime = 0;

  Simulator(YamlMap yamlData, {this.verbose = false}) {
    for (final name in yamlData.keys) {
      final fields = yamlData[name];
      // replace print statements with process creation
      switch (fields['type']) {
        case 'singleton':
          final duration = (fields['duration'] as num).toDouble();
          final arrival = (fields['arrival'] as num).toDouble();
          processes
              .add(SingletonProcess(name, arrival.toInt(), duration.toInt()));
          break;
        case 'periodic':
          final duration = (fields['duration'] as num).toDouble();
          final interarrivalTime =
              (fields['interarrival-time'] as num).toDouble();
          final firstArrival = (fields['first-arrival'] as num).toDouble();
          final numRepetitions = fields['num-repetitions'] as int;
          processes.add(PeriodicProcess(name, firstArrival.toInt(),
              duration.toInt(), interarrivalTime.toInt(), numRepetitions));
          break;
        case 'stochastic':
          final meanDuration = (fields['mean-duration'] as num).toDouble();
          final meanInterarrivalTime =
              (fields['mean-interarrival-time'] as num).toDouble();
          final firstArrival = (fields['first-arrival'] as num).toInt();
          final end = (fields['end'] as num).toInt();
          processes.add(StochasticProcess(
              name, firstArrival, meanDuration, meanInterarrivalTime, end));
          break;
      }
    }
  }

  void run() {
    for (final process in processes) {
      eventQueue.addAll(process.generateEvents());
    }

    // Sort events by arrival time
    eventQueue.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));

    // Simulate queueing
    List<Event> processedEvents = [];
    while (eventQueue.isNotEmpty) {
      final event = eventQueue.removeAt(0);
      if (event.arrivalTime > currentTime) {
        currentTime = event.arrivalTime;
      }
      event.startTime = currentTime;
      event.waitTime = (event.startTime ?? 0) - event.arrivalTime;
      currentTime += event.duration;
      processedEvents.add(event);

      if (verbose) {
        print(
            't = ${event.startTime}: ${event.processName}, duration ${event.duration} started (arrived @ ${event.arrivalTime}, waited ${event.waitTime})');
      }
    }
    printReport(processedEvents);
  }

  void printReport(List<Event> events) {
    // Aggregate statistics per process and overall
    Map<String, List<Event>> eventByProcess = {};
    for (final event in events) {
      eventByProcess.putIfAbsent(event.processName, () => []).add(event);
    }

    print('--------------------------\n# Per-process statistics\n');
    eventByProcess.forEach((processName, events) {
      final totalWaitTime =
          events.fold(0, (sum, event) => sum + (event.waitTime ?? 0));
      final avgWaitTime = totalWaitTime / events.length;
      print(
          ('$processName:\n Events generated: ${events.length}\n Total wait time: $totalWaitTime\n Average wait time: ${avgWaitTime.toStringAsFixed(2)}\n'));
    });

    final totalEvents = events.length;
    final totalWaitTime =
        events.fold(0, (sum, event) => sum + (event.waitTime ?? 0));
    final avgWaitTime = totalWaitTime / totalEvents;
    print('--------------------------\n# Summary statistics\n');
    print(
        'Total num events: $totalEvents\nTotal wait time: $totalWaitTime\nAverage wait time: ${avgWaitTime.toStringAsFixed(2)}');
  }
}
