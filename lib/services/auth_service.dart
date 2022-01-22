import 'dart:convert';

import 'package:e_commerce1/models/product.dart';
import 'package:e_commerce1/models/category.dart';
import 'package:e_commerce1/screens/user_screens/HomeScreen/Components/popular_products.dart';
import 'package:e_commerce1/screens/user_screens/categories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  AuthenticationService(this._firebaseAuth);
  Stream<User?> get authStateChanges => _firebaseAuth.idTokenChanges();

  final database = FirebaseDatabase.instance; //database reference object
  final storage = firebase_storage.FirebaseStorage.instance;


  Future<List<Product>> getAllProducts() async {
    var data = await database.ref("Products").once();

    List<Product> Products = [];
    for (var element in data.snapshot.children) {
      Map valueMap = json.decode(jsonEncode(element.value));
      List<String> imgs = [];
      for (String image in valueMap['images']) {
        String img = await storage.ref('products/' + image).getDownloadURL();
        imgs.add(img);
      }
      valueMap["images"] = imgs;
      Products.add(Product.fromJson(valueMap));
    }
    return Products;
  }

  Future<List<Product>> PopularProducts() async {
    var data = await database.ref("Products").once();

    List<Product> Products = [];
    for (var element in data.snapshot.children) {
      Map valueMap = json.decode(jsonEncode(element.value));
      if (valueMap['rating']> 3){
        List<String> imgs = [];
        for (String image in valueMap['images']) {
          String img = await storage.ref('products/' + image).getDownloadURL();
          imgs.add(img);
        }
        valueMap["images"] = imgs;
        Products.add(Product.fromJson(valueMap));
      }
    }
    return Products;
  }

  Future AddProduct({required String name,required String type,required String desc,required String price,required String path}) async{
    List<String> imgs = [path];
    int price_int =int.parse(price);
    database.ref().child("Products").push().set({
      "Name": "" + name,
      "Type": "" + type,
      "desc": "" + desc,
      "price": price_int,
      "images": [path],
      "id": 1,
      "rating": 5,
    }).then((_) {
    });
  }



  Future<List<Category>> getAllCategories() async {
    var data = await database.ref("Categories").once();



    List<Category> Cat = [];
    for (var element in data.snapshot.children) {
      Map valueMap = json.decode(jsonEncode(element.value));
      String img = await storage.ref('categories/' + valueMap["image"]).getDownloadURL();
      valueMap["image"] = img;
      Cat.add(Category.fromJson(valueMap));
    }

    return Cat;
  }
  Future<String?> signUp(
      {required String email, required String password, required String name}) async {
    try {
      var result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      result.user!.updateDisplayName(name);
      database.ref().child("users").push().set({
        "uid": ""+result.user!.uid,
        "Address": "",
        "Type": "user",
        "about": "",
        "phone": "",
      }).then((_) {
      });

      return "Signed up";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  bool isLoggedin() {
    if(_firebaseAuth.currentUser == null) {
      return false;
    }
    return true;
  }

  Future<Map> userInfo() async {
    if(_firebaseAuth.currentUser != null) {
      var about = await database.ref().child("users").orderByChild("uid").equalTo(_firebaseAuth.currentUser!.uid).once();
      Map valueMap = json.decode(jsonEncode(about.snapshot.value));
      String? name = getName();
      String? email = getEmail();
      valueMap[valueMap.keys.first]['name'] = name==null?"":name;
      valueMap[valueMap.keys.first]['email'] = email==null?"":email;
      return valueMap[valueMap.keys.first];
    }
    return {};
  }

  String? getName() {
    if(_firebaseAuth.currentUser != null) {
      return _firebaseAuth.currentUser!.displayName;
    }
    return "";
  }

  String? getUID() {
    if(_firebaseAuth.currentUser != null) {
      return _firebaseAuth.currentUser!.uid;
    }
    return "";
  }
  String? getEmail() {
    if(_firebaseAuth.currentUser != null) {
      return _firebaseAuth.currentUser!.email;
    }
    return "";
  }

  Future<String?> signIn(
      {required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      _firebaseAuth.setPersistence(Persistence.SESSION);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("uid", _firebaseAuth.currentUser!.uid);
      prefs.setBool("isLoggedIn", true);
      prefs.setString("Email", email);
      return "Signed in";
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
