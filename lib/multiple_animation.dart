import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_tilt/flutter_tilt.dart'; // For rootBundle to load images

void main() {
  runApp(MaterialApp(
    home: CircularScaleInRotateImagesScreen(),
  ));
}

class CircularScaleInRotateImagesScreen extends StatefulWidget {
  @override
  _CircularScaleInRotateImagesScreenState createState() =>
      _CircularScaleInRotateImagesScreenState();
}

class _CircularScaleInRotateImagesScreenState
    extends State<CircularScaleInRotateImagesScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;


  //slide animation
  late AnimationController _slidController;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _scaleAnimation;

  List<Uint8List> _images = []; // List to hold image byte data

  @override
  void initState() {
    super.initState();
    _loadImages(); // Load images into memory
    initSlideController();
    // Initialize AnimationControllers and Animations for scaling in each image
    _scaleControllers = List.generate(6, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    });

    _scaleAnimations = _scaleControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Initialize the rotation controller with smooth start and stop
    _rotateController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ).drive(Tween<double>(begin: 0, end: 2 * pi));

    // Start the scale-in animations
    _startScaleInAnimations();
  }

  Future<void> _loadImages() async {
    // Load images from images
    List<String> imagePaths = [
      'images/item1.png',
      'images/item2.png',
      'images/item3.png',
      'images/item4.png',
      'images/item5.png',
      'images/item6.png',
    ];

    for (String path in imagePaths) {
      final ByteData data = await rootBundle.load(path);
      _images.add(data.buffer.asUint8List());
    }
    setState(() {});
  }

  void _startScaleInAnimations() {
    for (int i = 0; i < _scaleControllers.length; i++) {
      Timer(Duration(milliseconds: i * 500), () {
        _scaleControllers[i].forward().whenComplete(() {
          if (i == _scaleControllers.length - 1) {
            _rotateController.forward();
          }
        });
      });
    }
  }
  initSlideController() {
    _slidController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Slide animation for the box from bottom to its original position
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Start from the bottom
      end: const Offset(0, 0.3), // End at original position
    ).animate(
      CurvedAnimation(parent: _slidController, curve: Curves.easeInOut),
    );

    // Slide animation for the text from top to its original position
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -3), // Start far above the screen
      end: const Offset(0, 27), // End at original position in the center
    ).animate(
      CurvedAnimation(parent: _slidController, curve: Curves.easeInOut),
    );

    // Scale animation from 0 to 1
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slidController, curve: Curves.easeInOut),
    );

    _slidController.forward(); // Start the animations
  }

  @override
  void dispose() {
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double horizontalRadius = 500; // Horizontal radius for the oval path
    double verticalRadius = 250;   // Vertical radius for the oval path
    double diameter = 2 * (horizontalRadius + 150); // Adjust diameter to fit the entire oval

    return Scaffold(
      body: Center(
        child: _images.isEmpty
            ? CircularProgressIndicator() // Show a loading indicator while images are loading
            : Container(
          height: double.infinity,
              width: double.infinity,
              color: Colors.amber,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedBuilder(
                      animation: _rotateAnimation,
                      builder: (context, child) {
                        return Container(
                          width: diameter,
                          height: diameter,
                          alignment: Alignment.center,
                          child: Stack(
                            children: List.generate(6, (index) {
                              double angle = (2 * pi / 6) * index - _rotateAnimation.value;
                              double x = horizontalRadius * cos(angle) + horizontalRadius - 100; // Adjust x position for oval
                              double y = verticalRadius * sin(angle) + verticalRadius - 100;     // Adjust y position for oval
                              return Positioned(
                                left: x + 80,
                                top: y + 100,
                                child: ScaleTransition(
                                  scale: _scaleAnimations[index],
                                  child: Image.memory(
                                    _images[index],
                                    height: 350,
                                    width: 350,
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                  AbsorbPointer(
                    absorbing: true,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            height: 500,
                            width: 500,
                            padding: const EdgeInsets.all(10),
                            child: Tilt(
                              borderRadius: BorderRadius.circular(48),
                              tiltConfig: const TiltConfig(
                                initial: Offset(-2, -2),
                                enableReverse: true,
                                leaveCurve: Curves.easeInOutCubicEmphasized,
                              ),
                              lightConfig: const LightConfig(disable: true, color: Colors.transparent),
                              shadowConfig: const ShadowConfig(disable: true , color: Colors.transparent),
                              childLayout: const ChildLayout(
                                  inner: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TiltParallax(
                                          filterQuality: FilterQuality.none,
                                          size: Offset(5,-4),
                                          child: Text('MIX&',
                                              style: TextStyle(color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'FjallaOne',
                                                  fontSize: 105
                                              )),
                                        ),
                                        TiltParallax(
                                          filterQuality: FilterQuality.none,
                                          size: Offset(5,-4),
                                          child: Text('MATCH!',
                                              style: TextStyle(color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'FjallaOne',
                                                  fontSize: 104
                                              )),
                                        ),
                                        TiltParallax(
                                          filterQuality: FilterQuality.none,
                                          size: Offset(5,-4),
                                          child: Text('\$5.99',
                                              style: TextStyle(color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'FjallaOne',
                                                  fontSize: 104
                                              )),
                                        ),
                                      ],
                                    )
                                  ],
                                  outer: [
                                    Column(
                                      children: [
                                        TiltParallax(
                                          size: Offset(2,-5),
                                          child: Text('MIX&', style: TextStyle(color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'FjallaOne',
                                              fontSize: 105
                                          )),
                                        ),
                                        TiltParallax(
                                          size: Offset(2,-5),
                                          child: Text('MATCH!', style: TextStyle(color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'FjallaOne',
                                              fontSize: 105
                                          )),
                                        ),
                                        TiltParallax(
                                          size: Offset(2,-5),
                                          child: Text('\$5.99', style: TextStyle(color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'FjallaOne',
                                              fontSize: 105
                                          )),
                                        ),
                                      ],
                                    )
                                  ]
                              ),
                              child:  const SizedBox(width: 300, height: 300, ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 38.0),
                      child: Text(
                        "Must Select in increments of 2 valid Mix & Match options to receive discount",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                            fontSize: 18, fontWeight: FontWeight.normal, fontFamily: 'FjallaOne'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
