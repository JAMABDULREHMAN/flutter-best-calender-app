import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class Event {
  final String title;
  final String description;
  Event(this.title, this.description);
}

class CalendarProvider with ChangeNotifier {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Event> _events = [];

  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  List<Event> get events => _events;

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  void addEvent(Event event) {
    _events.add(event);
    notifyListeners();
  }

  void removeEvent(Event event) {
    _events.remove(event);
    notifyListeners();
  }

  void loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventTitles = prefs.getStringList('event_titles') ?? [];
    final eventDescriptions = prefs.getStringList('event_descriptions') ?? [];

    _events = List.generate(eventTitles.length, (index) {
      return Event(eventTitles[index], eventDescriptions[index]);
    });
    notifyListeners();
  }

  void saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventTitles = _events.map((e) => e.title).toList();
    final eventDescriptions = _events.map((e) => e.description).toList();
    prefs.setStringList('event_titles', eventTitles);
    prefs.setStringList('event_descriptions', eventDescriptions);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Calendar App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: CalendarScreen(),
      ),
    );
  }
}

class CalendarScreen extends StatelessWidget {
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar app')),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: provider.focusedDay,
                selectedDayPredicate: (day) =>
                    isSameDay(provider.selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  provider.setSelectedDay(selectedDay);
                  provider.setFocusedDay(focusedDay);
                },
                onPageChanged: (focusedDay) {
                  provider.setFocusedDay(focusedDay);
                },
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _eventTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _eventDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Event Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final event = Event(
                    _eventTitleController.text,
                    _eventDescriptionController.text,
                  );
                  provider.addEvent(event);
                  provider.saveEvents();
                  _eventTitleController.clear();
                  _eventDescriptionController.clear();
                  _showNotification(event);
                },
                child: const Text('Add Event'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.events.length,
                  itemBuilder: (context, index) {
                    final event = provider.events[index];
                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.description),
                      onLongPress: () {
                        provider.removeEvent(event);
                        provider.saveEvents();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNotification(Event event) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Event Added!',
      event.title,
      platformDetails,
    );
  }
}
