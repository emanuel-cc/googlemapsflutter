/*
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
import 'dart:async';
import 'dart:convert';
import 'data/error.dart';
import 'data/place_response.dart';
import 'data/result.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacesSearchMapSample extends StatefulWidget {
  final String keyword;
  PlacesSearchMapSample(this.keyword);

  @override
  State<PlacesSearchMapSample> createState() {
    return _PlacesSearchMapSample();
  }
}

class _PlacesSearchMapSample extends State<PlacesSearchMapSample> {
  static const String _API_KEY = 'AIzaSyAAw4woNIssZ0P5Lonws9W-9LTRHRCMyqc';

  static double latitude = 40.7484405;// 20.9333
  static double longitude = -73.9878531; //-73.9878531 -89.0167
  static const String baseUrl =
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json";

  List<Marker> markers = <Marker>[];
  Error error;
  List<Result> places;
  List resultados;
  bool searching = true;
  String keyword;

  Completer<GoogleMapController> _controller = Completer();
  

  static final CameraPosition _myLocation = CameraPosition(
    target: LatLng(latitude, longitude),
    zoom: 12,
    bearing: 15.0,
    tilt: 75.0
  );

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Stack(
        children:[ 
            GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _myLocation,
            onMapCreated: (GoogleMapController controller) {
              _setStyle(controller);
              _controller.complete(controller);
            },
            markers: Set<Marker>.of(markers),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: FutureBuilder(
              future: result(latitude, longitude),
              builder: (context, AsyncSnapshot<List<Result>> snapshot){
                if(snapshot.hasData){
                  final datos = snapshot.data;
                    return Container(
                      width: double.infinity,
                      height: 60.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: datos.length,
                        itemBuilder: (context,index){
                          return elemento(datos[index].icon,datos[index].name);
                        },
                      ),
                    );
                  
                }else{
                  return CircularProgressIndicator();
                }
                
              },
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: FloatingActionButton.extended(
              onPressed: () {
                searchNearby(latitude, longitude);
                result(latitude, longitude);
              },
              label: Text('Places Nearby'),
              icon: Icon(Icons.place),
            ),
          )
        ]
      ),
      /*floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          searchNearby(latitude, longitude);
          result(latitude, longitude);
        },
        label: Text('Places Nearby'),
        icon: Icon(Icons.place),
      ),*/
    );
  }

  Widget elemento(String result,String nombre){
    return Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            width: 40.0,
            height: 40.0,
            child: Image.network(result),
          ),
          Text(nombre)
        ],
      ),
    );
  }

  void _setStyle(GoogleMapController controller) async {
    String value = await DefaultAssetBundle.of(context).loadString('assets/maps_style.json');
    controller.setMapStyle(value);
  }

  void searchNearby(double latitude, double longitude) async {
    setState(() {
      markers.clear();
    });
    String url =
        '$baseUrl?key=$_API_KEY&location=$latitude,$longitude&radius=10000&keyword=${widget.keyword}';//&keyword=${widget.keyword}
    print(url);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _handleResponse(data);
    } else {
      throw Exception('An error occurred getting places nearby');
    }

    // make sure to hide searching
    setState(() {
      searching = false;
    });
  }

  Future<List<Result>> result(double latitude, double longitude)async{
    Map<String,dynamic> data;
    String url =
        '$baseUrl?key=$_API_KEY&location=$latitude,$longitude&radius=10000&keyword=${widget.keyword}';
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
       data = json.decode(response.body);
      places = PlaceResponse.parseResults(data['results']);
    } else {
      throw Exception('An error occurred getting places nearby');
    }

    _handleResponse(data);
    print(data);

    return places;
  }

  void _handleResponse(data){
    // bad api key or otherwise
      if (data['status'] == "REQUEST_DENIED") {
        setState(() {
          error = Error.fromJson(data);
        });
        // success
      } else if (data['status'] == "OK") {
        setState(() {
          places = PlaceResponse.parseResults(data['results']);
          for (int i = 0; i < places.length; i++) {
            markers.add(
              Marker(
                markerId: MarkerId(places[i].placeId),
                position: LatLng(places[i].geometry.location.lat,
                    places[i].geometry.location.long),
                infoWindow: InfoWindow(
                    title: places[i].name, snippet: places[i].vicinity),
                onTap: () {},
              ),
            );

            
          }

          
        });
      } else {
        print(data);
      }
  }
}
