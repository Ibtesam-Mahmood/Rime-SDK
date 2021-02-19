import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pollar/util/config_reader.dart';


class Request {
  // String local = 'https://isaiah.localtunnel.me/api';//'http://localhost:3001/api';
  String local = 'http://ss-0f5cc2ac.localhost.run/api';
  String remote = ConfigReader.getDevelopmentURL(); //'some server ip address/ domain name';
  bool testing = false;
  bool hosting = true;
  String get baseUrl => hosting ? remote : local;
  Map<String, String> defaultHeaders = {};

  ///Stores the current outgoing requests from the client
  final Map<String, Future<http.Response>> _currentRequests = Map<String, Future<http.Response>>();

  Map<String, String> _getFinalHeaders(Map<String, String> headers, {String contentType}) {
    Map<String, String> finalHeaders = {};
    if(testing) finalHeaders['testing']='true';
    finalHeaders.addAll(defaultHeaders);
    if (headers != null){
      finalHeaders.addAll(headers);}
    if (contentType != null){
      finalHeaders['content-type'] = contentType;}
    return finalHeaders;
  }
  
  //old implementation w/ cookies
  /* Future<http.Response> _get(String url, {Map<String, String> headers}) {
    return http.get(baseUrl + url, headers: _getFinalHeaders(headers));
  }
  Future<http.Response> _post(String url, {Map<String, String> headers, dynamic body, String contentType}) {
    return http.post(baseUrl + url, body: body, headers: _getFinalHeaders(headers, contentType: contentType));
  }
  Future<http.Response> _put(String url, {Map<String, String> headers, dynamic body, String contentType}) {
    return http.put(baseUrl + url, body: body, headers: _getFinalHeaders(headers, contentType: contentType));
  }
  Future<http.Response> _delete(String url, {Map<String, String> headers}) {
    return http.delete(baseUrl + url, headers: _getFinalHeaders(headers));
  } */

  //new implementatiion that response with a Map and also set cookie headers
  Future<Map> get(String url, {Map<String, String> headers}) async {
    http.Response response = await _cGET(baseUrl + url, _getFinalHeaders(headers));
    _updateCookie(response);
    Map map = json.decode(response.body);
    map['statusCode'] = response.statusCode;
    return map;
  }

  Future<Map> post(String url, {Map<String, String> headers, dynamic body, String contentType}) async {
    http.Response response = await _cPOST(baseUrl + url, _getFinalHeaders(headers, contentType: contentType), body: body);
    _updateCookie(response);
    Map map = json.decode(response.body);
    map['statusCode'] = response.statusCode;
    return map;
  }
 
  Future<Map> put(String url, {Map<String, String> headers, dynamic body, String contentType}) async {
    http.Response response = await _cPUT(baseUrl + url, _getFinalHeaders(headers, contentType: contentType), body: body);
    _updateCookie(response);
    Map map = json.decode(response.body);
    map['statusCode'] = response.statusCode;
    return map;
  }

  Future<Map> delete(String url, {Map<String, String> headers, dynamic body, String contentType}) async {
    http.Response response = await _cDELETE(baseUrl + url, _getFinalHeaders(headers));
    _updateCookie(response);
    Map map = json.decode(response.body);
    map['statusCode'] = response.statusCode;
    return map;
  }

  //todo because we need to use the request will have to change some things.
  void _updateCookie(http.Response response) {
    String rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      defaultHeaders['cookie'] = (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  //Cache functions

  ///Primary listener for the event to finish
  ///Disposes of the refrence to the request upon completion
  Future<void> _primaryRequestListener(Future<http.Response> request, String key) async {
    await request;
    _currentRequests.remove(key);
  }

  ///Get Request
  ///
  ///Retreives or stores a request into the currentRequests
  Future<http.Response> _cGET(String url, Map<String, String> headers) {
    //The key for the request in the cahce
    String key = 'GET - ' + url.replaceAll(baseUrl, '') + jsonEncode(headers);

    Future<http.Response> request = _currentRequests[key];
    
    if(request == null){ //No current request

      //Creates a new request and stores it into the cache
      Future<http.Response> newRequest = http.get(url, headers: headers);

      _currentRequests[key] = newRequest;

      //Define primary listener
      //Removes the item from the cache when the request is complete
      _primaryRequestListener(newRequest, key);
      
      return newRequest;
    }
    else{ //Found current request
      return request; //Retruns the cached request
    }
  }

  ///Post Request
  ///
  ///Retreives or stores a request into the currentRequests
  Future<http.Response> _cPOST(String url, Map<String, String> headers, {dynamic body = ''}){
    //The key for the request in the cahce
    String key = 'POST - ' + url + jsonEncode(headers) + jsonEncode(body);

    Future<http.Response> request = _currentRequests[key];
    
    if(request == null){ //No current request
      //Creates a new request and stores it into the cache
      Future<http.Response> newRequest = http.post(url, headers: headers, body: body);

      _currentRequests[key] = newRequest;

      //Define primary listener
      //Removes the item from the cache when the request is complete
      _primaryRequestListener(newRequest, key);

      //Retruns the new request
      return newRequest;
    }
    else{ //Found current request
      return request; //Retruns the cached request
    }
  }

  ///Put Request
  ///
  ///Retreives or stores a request into the currentRequests
  Future<http.Response> _cPUT(String url, Map<String, String> headers, {dynamic body = ''}){
    //The key for the request in the cahce
    String key = 'PUT - ' + url + jsonEncode(headers) + jsonEncode(body);

    Future<http.Response> request = _currentRequests[key];
    
    if(request == null){ //No current request
      //Creates a new request and stores it into the cache
      Future<http.Response> newRequest = http.put(url, headers: headers, body: body);

      _currentRequests[key] = newRequest;

      //Define primary listener
      //Removes the item from the cache when the request is complete
      _primaryRequestListener(newRequest, key);

      //Retruns the new request
      return newRequest;
    }
    else{ //Found current request
      return request; //Retruns the cached request
    }
  }

  ///Delete Request
  ///
  ///Retreives or stores a request into the currentRequests
  Future<http.Response> _cDELETE(String url, Map<String, String> headers){
    //The key for the request in the cahce
    String key = 'DELETE - ' + url + jsonEncode(headers);

    Future<http.Response> request = _currentRequests[key];
    
    if(request == null){ //No current request
      //Creates a new request and stores it into the cache
      Future<http.Response> newRequest = http.delete(url, headers: headers);

      _currentRequests[key] = newRequest;

      //Define primary listener
      //Removes the item from the cache when the request is complete
      _primaryRequestListener(newRequest, key);

      //Retruns the new request
      return newRequest;
    }
    else{ //Found current request
      return request; //Retruns the cached request
    }
  }

  //Removes evaluated requests
  // void cleanCachedRequests(){
  //   _currentRequests.removeWhere((k, v) {
  //     return v
  //   });
  // }

}
Request request = Request();

//default headers
//user auth info
//send post request,get request, put request, delete request

