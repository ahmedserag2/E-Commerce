import 'package:e_commerce1/models/product.dart';
import 'package:e_commerce1/models/product_selected.dart';
import 'package:e_commerce1/services/orders_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Order{
  Map<String, dynamic> cartItems = {};
  final OrdersService _ordersService = OrdersService();
  String? userId;
  String? totalPrice;
  String? orderId;
  String? address;
  double? latitude;
  double? longitude;
  String? timeStamp;
  List<ProductSelected>? productsOrdered;


  Order({required this.userId,required this.totalPrice,required this.orderId,required this.productsOrdered,required this.address,required this.timeStamp,required this.longitude,required this.latitude});

  Order.fromMap(this.cartItems);

  factory Order.fromRTDB(String key,Map<dynamic,dynamic> value,String userId){
    List<ProductSelected> productsOrdered = [];
    //print(value);
    String orderId = key;
    //print(key);
    Map<dynamic,dynamic> orderJson = value;
    String totalPrice = orderJson['totalPrice'].toString();
    String address = orderJson['address'];
    String timeStamp = orderJson['timeStamp'];
    double latitude = orderJson['latitude'];
    double longitude = orderJson['longitude'];

    //print(orderJson['ProductsOrdered']);
    var productsOrderedJson = orderJson['ProductsOrdered'] as List<dynamic>;
    //List<ProductSelected> productsOrdered = [];
    productsOrderedJson.forEach((element) {
      //print(element);
      var productOrderedJson = List.from(element.values);
      print('got in');
      int? quantity;
      Map<dynamic,dynamic>? productJson;
      if(productOrderedJson[0].runtimeType == 1.runtimeType)
      {
        quantity = productOrderedJson[0];
        productJson = Map.from(productOrderedJson[1]);
      }
      else {
        quantity = productOrderedJson[1];
        productJson = Map.from(productOrderedJson[0]);
      }

      //print(productOrderedJson[0]);


      productsOrdered.add(ProductSelected(product: Product.fromJson(productJson!,2),numOfItem: quantity!));
    });
    Order o = Order(
        userId: userId,
        totalPrice: totalPrice,
        productsOrdered: productsOrdered,orderId: key,
    address: address,timeStamp: timeStamp,latitude: latitude,longitude: longitude);

    return o;

  }


  save() async
  {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //validate if not logged in
    String userId = prefs.getString("uid")!;
    /*
    Map<String,dynamic> order = {
      userId:userId,
      'order':cartItems
    };*/
    await _ordersService.save(order: cartItems,userId:userId);
  }

}

