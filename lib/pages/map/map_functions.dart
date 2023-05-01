import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:parkflow/components/custom_button.dart';
import 'package:parkflow/components/custom_map_button.dart';
import 'package:provider/provider.dart';
import '../../model/user/user_logged_controller.dart';
import 'package:intl/intl.dart';

final _firestore = FirebaseFirestore.instance;
// Dit is allemaal voor de tijd
Duration selectedTime = const Duration(hours: 0, minutes: 0);

//tijd formateer methodes
String formatDateTime(DateTime dateTime) {
  return DateFormat('dd/MM HHumm').format(dateTime);
}

void getMarkersFromDatabase(BuildContext context,
    void Function(List<Marker> markers) onMarkersFetched) async {
  final markersSnapshot = await _firestore.collection('markers').get();
  List<Marker> markers = markersSnapshot.docs.map((doc) {
    LatLng latLng = LatLng(doc['latitude'], doc['longitude']);
    String userId = doc['userId'];
    DateTime startTime = doc['startTime'].toDate();
    DateTime endTime = doc['endTime'].toDate();
    bool isGreenMarker = doc['isGreenMarker'];
    return createMarkersFromDatabase(
        context, latLng, userId, startTime, endTime, isGreenMarker);
  }).toList();
  onMarkersFetched(markers);
}

void createMarker(LatLng latlng, String userId, BuildContext context,
    void Function(Marker newMarker) onMarkerCreated) {
  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now().add(const Duration(minutes: 1));
  bool isGreenMarker = true;
  saveMarkerToDatabase(latlng, userId, startTime, endTime, isGreenMarker);
  Marker newMarker = createMarkersFromDatabase(
      context, latlng, userId, startTime, endTime, isGreenMarker);
  onMarkerCreated(newMarker);
}

Marker createMarkersFromDatabase(BuildContext context, LatLng latlng,
    String userId, DateTime startTime, DateTime endTime, bool isGreenMarker) {
  final userLogged = Provider.of<UserLogged>(context, listen: false);
  final userEmail = userLogged.email.trim();
  Color markerColor;

  if (isGreenMarker) {
    markerColor = Colors.green;
  } else if (userEmail == userId) {
    markerColor = Colors.blue;
  } else {
    markerColor = Colors.black;
  }

  return Marker(
    width: 60.0,
    height: 60.0,
    point: latlng,
    builder: (ctx) => GestureDetector(
      onTap: () {
        if (isGreenMarker) {
          showPopup(context, latlng, startTime, endTime, userId, true);
        }
      },
      child: Container(
        child: Icon(Icons.location_on, color: markerColor, size: 40),
      ),
    ),
  );
}

Future<void> saveMarkerToDatabase(LatLng latlng, String userId,
    DateTime startTime, DateTime endTime, bool isGreenMarker) async {
  QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
      .collection('markers')
      .where('latitude', isEqualTo: latlng.latitude)
      .where('longitude', isEqualTo: latlng.longitude)
      .get();

  for (var doc in querySnapshot.docs) {
    await _firestore.collection('markers').doc(doc.id).delete();
  }

  await _firestore.collection('markers').add({
    'latitude': latlng.latitude,
    'longitude': latlng.longitude,
    'userId': userId,
    'startTime': startTime,
    'endTime': endTime,
    'isGreenMarker': isGreenMarker,
  });
}

Future<void> removeExpiredMarkers() async {
  final markersSnapshot = await _firestore.collection('markers').get();
  for (var doc in markersSnapshot.docs) {
    DateTime endTime = doc['endTime'].toDate();
    if (endTime.isBefore(DateTime.now())) {
      await _firestore.collection('markers').doc(doc.id).delete();
    }
  }
}

void showPopup(BuildContext context, LatLng latLng, DateTime startTime,
    DateTime endTime, String userId, bool isGreenMarker) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setState) {
        DateTime endTime = DateTime.now().add(selectedTime);

        Duration selectedDuration = Duration();

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Straat naam hier'),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      iconSize: 30,
                    ),
                  ],
                ),
                const Divider(
                  color: Colors.black,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                const Text('Hoe lang gaat u parkeren?'),
                SizedBox(
                  height: 180,
                  child: CupertinoDatePicker(
                    initialDateTime: DateTime(0).add(selectedTime),
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    onDateTimeChanged: (DateTime value) {
                      setState(() {
                        selectedTime =
                            Duration(hours: value.hour, minutes: value.minute);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text('van ${formatDateTime(DateTime.now())}'),
                Text('tot  ${formatDateTime(endTime)}'),
                const SizedBox(height: 20),
                CustomMapButton(
                  onPressed: () async {
                    if (isGreenMarker) {
                      final userLogged =
                          Provider.of<UserLogged>(context, listen: false);
                      await saveMarkerToDatabase(latLng, userLogged.email,
                          startTime, endTime, false);
                    } else {
                      await saveMarkerToDatabase(
                          latLng, userId, startTime, endTime, true);
                    }
                    Navigator.pop(context);
                  },
                  backgroundColor: Colors.blueGrey,
                  height: 70,
                  label: 'Parkeren',
                  width: double.infinity,
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}
