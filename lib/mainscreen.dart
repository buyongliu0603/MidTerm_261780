import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:midterm_261780/destination.dart';
import 'package:midterm_261780/infopage.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:toast/toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List locdata;
  String curtype = "Kedah";
  List _state = [
    "Johor",
    "Kedah",
    "Kelantan",
    "Perak",
    "Selangor",
    "Melaka",
    "Negeri Sembilan",
    "Pahang",
    "Perlis",
    "Penang",
    "Sabah",
    "Sarawak",
    "Terengganu",
  ];
  int curnumber = 1;
  double screenHeight, screenWidth;

  String selectedstate;

  @override
  void initState() {
    super.initState();
    _loadData();
    loadPref();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    if (locdata == null) {
      return Scaffold(
          appBar: AppBar(
            title: Text('Locations List'),
          ),
          body: Container(
              child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Loading Locations",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                )
              ],
            ),
          )));
    } else {
      return WillPopScope(
          onWillPop: _onBackPressed,
          child: Scaffold(
              appBar: AppBar(
                title: Text(
                  'Locations List',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              body: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    TableCell(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(5, 1, 5, 1),
                        height: 40,
                        child: Container(
                          height: 40,
                          child: DropdownButton(
                            //sorting dropdownoption
                            hint: Text(
                              'state',
                              style: TextStyle(
                                color: Color.fromRGBO(101, 255, 218, 50),
                              ),
                            ), // Not necessary for Option 1
                            value: selectedstate,
                            onChanged: (newValue) {
                              setState(() {
                                selectedstate = newValue;
                                print(selectedstate);
                              });
                              _sortItem(selectedstate);
                            },
                            items: _state.map((selectedstate) {
                              return DropdownMenuItem(
                                child: new Text(selectedstate,
                                    style: TextStyle(
                                        color:
                                            Color.fromRGBO(101, 255, 218, 50))),
                                value: selectedstate,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Text(curtype,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Expanded(
                        child: GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio:
                                (screenWidth / screenHeight) / 0.8,
                            children: List.generate(locdata.length, (index) {
                              return Container(
                                  child: Card(
                                      elevation: 10,
                                      child: Padding(
                                        padding: EdgeInsets.all(5),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            GestureDetector(
                                              onTap: () =>
                                                  _onLocationDetail(index),
                                              child: Container(
                                                height: screenHeight / 5.9,
                                                width: screenWidth / 3.5,
                                                child: ClipOval(
                                                    child: CachedNetworkImage(
                                                  fit: BoxFit.scaleDown,
                                                  imageUrl:
                                                      "http://slumberjer.com/visitmalaysia/images/${locdata[index]['imagename']}",
                                                  placeholder: (context, url) =>
                                                      new CircularProgressIndicator(),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          new Icon(Icons.error),
                                                )),
                                              ),
                                            ),
                                            Text(locdata[index]['loc_name'],
                                                maxLines: 1,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                            Text("State: " + locdata[index]['state'],
                                                maxLines: 1,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      )));
                            })))
                  ],
                ),
              )));
    }
  }

  _onLocationDetail(int index) async {
    print(locdata[index]['loc_name']);
    Destination destination = new Destination(
        pid: locdata[index]['pid'],
        locname: locdata[index]['loc_name'],
        state: locdata[index]['state'],
        description: locdata[index]['description'],
        latitude: locdata[index]['latitude'],
        longitude: locdata[index]['longitude'],
        url: locdata[index]['url'],
        contact: locdata[index]['contact'],
        address: locdata[index]['address'],
        imagename: locdata[index]['imagename']);

    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => InfoPage(
                  destination: destination,
                )));
    _loadData();
  }

  void _loadData() {
    String urlLoadJobs =
        "http://slumberjer.com/visitmalaysia/load_destinations.php";
    http.post(urlLoadJobs, body: {}).then((res) {
      setState(() {
        var extractdata = json.decode(res.body);
        locdata = extractdata["locations"];
        _sortItem(curtype);
      });
    }).catchError((err) {
      print(err);
    });
  }

  void _sortItem(String state) {
    try {
      ProgressDialog pr = new ProgressDialog(context,
          type: ProgressDialogType.Normal, isDismissible: true);
      pr.style(message: "Searching...");
      pr.show();
      String urlLoadJobs =
          "http://slumberjer.com/visitmalaysia/load_destinations.php";
      http.post(urlLoadJobs, body: {
        "state": state,
      }).then((res) {
        setState(() {
          curtype = state;
          var extractdata = json.decode(res.body);
          locdata = extractdata["locations"];
          FocusScope.of(context).requestFocus(new FocusNode());
          pr.dismiss();
        });
      }).catchError((err) {
        print(err);
        pr.dismiss();
      });
      pr.dismiss();
    } on TimeoutException catch (_) {
      Toast.show("Time out", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    } on SocketException catch (_) {
      Toast.show("Time out", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    } catch (e) {
      Toast.show("Error", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    }
  }

  Future<bool> _onBackPressed() {
    savepref(true);
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            title: new Text(
              'Are you sure?',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            content: new Text(
              'Do you want to exit an App',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            actions: <Widget>[
              MaterialButton(
                  onPressed: () {
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  },
                  child: Text(
                    "Exit",
                    style: TextStyle(
                      color: Color.fromRGBO(101, 255, 218, 50),
                    ),
                  )),
              MaterialButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Color.fromRGBO(101, 255, 218, 50),
                    ),
                  )),
            ],
          ),
        ) ??
        false;
  }
    Future<void> loadPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
      String state = (prefs.getString('state')) ?? '';
      setState(() {
        this.curtype = state ;
      });
    
  }
   void savepref(bool value) async {

     String state = curtype;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value) {
      //save preference
      await prefs.setString('state', state);
      Toast.show("Preferences have been saved", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
    } else {
      //delete preference
      await prefs.setString('state', '');
      Toast.show("Preferences have removed", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
    }
  }
}
