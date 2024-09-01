import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart' as myAuth;
import 'login_page.dart';
import 'profile_page.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DatabaseReference fdb_ref = FirebaseDatabase.instance.ref().child("test_db");

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final List<String> _itemDetails = ['Monitor', 'Laptop', 'Keyboard', 'Mobile', 'Mouse', 'Others', 'Others Details'];
  final Map<String, TextEditingController> _quantityControllers = {
    'Monitor': TextEditingController(),
    'Laptop': TextEditingController(),
    'Keyboard': TextEditingController(),
    'Mobile': TextEditingController(),
    'Mouse': TextEditingController(),
    'Others': TextEditingController(),
    'Others Details': TextEditingController(),
  };
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  Future<void> _pickImages(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      List<XFile>? pickedFiles;
      if (source == ImageSource.camera) {
        final XFile? pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null) {
          pickedFiles = [pickedFile];
        }
      } else {
        pickedFiles = await picker.pickMultiImage();
      }

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles!);
        });
      }
    } catch (e) {
      print("Image pick error: $e");
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Get selected items with quantities
        List<Map<String, dynamic>> selectedItems = _itemDetails
            .where((item) => _quantityControllers[item]!.text.isNotEmpty)
            .map((item) {
          return {
            'item': item,
            'quantity': _quantityControllers[item]!.text,
          };
        }).toList();

        var uuid = Uuid();
        final String pk = uuid.v4();

        // Get current timestamp for the filename
        String timestamp = DateFormat('ddMMyyyy_HHmmss').format(DateTime.now());

        // Upload images to Firebase Storage and get their URLs
        List<String> imageUrls = [];
        for (XFile image in _selectedImages) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('test_db')
              .child('$timestamp-${image.name}');
          await ref.putFile(File(image.path));
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }

        await FirebaseDatabase.instance.ref('test_db/$timestamp').set({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'itemDetails': selectedItems,
          'imageUrls': imageUrls,
          'userId': Provider.of<myAuth.AuthProvider>(context, listen: false).user?.uid,
        }).then((_) {
          _nameController.clear();
          _phoneController.clear();
          _addressController.clear();
          _quantityControllers.forEach((key, controller) => controller.clear());
          _selectedImages.clear();
          const snackBar = SnackBar(content: Text('Record Added Successfully, Will Contact you soon.'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }).catchError((error) {
          const snackBarError = SnackBar(content: Text('Error'));
          ScaffoldMessenger.of(context).showSnackBar(snackBarError);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred. Please try again.')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<myAuth.AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'), // Path to your background image
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(authProvider.user?.photoURL ?? 'https://via.placeholder.com/150'),
                    ),
                    SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${authProvider.user?.displayName ?? 'User'}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Email: ${authProvider.user?.email ?? 'No Email'}',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please Fill Required Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(labelText: 'Phone Number'),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(labelText: 'Address'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        Container(
                          color: Colors.lightGreenAccent,
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Item Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 10),
                        ..._itemDetails.map((item) {
                          if (item == 'Others Details') {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5.0),
                              child: TextFormField(
                                controller: _quantityControllers[item],
                                decoration: InputDecoration(
                                  labelText: 'Others Details',
                                  hintText: 'Please enter details of others items',
                                ),
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _quantityControllers[item],
                                      decoration: InputDecoration(labelText: 'Quantity'),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }).toList(),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImages(ImageSource.camera),
                              icon: Icon(Icons.camera),
                              label: Text('Camera'),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _pickImages(ImageSource.gallery),
                              icon: Icon(Icons.photo_library),
                              label: Text('Gallery'),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        if (_selectedImages.isNotEmpty)
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _selectedImages.map((image) {
                              return Image.file(
                                File(image.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              );
                            }).toList(),
                          ),
                        SizedBox(height: 20),
                        Center(
                          child: _isLoading
                              ? CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: Text('Submit'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
