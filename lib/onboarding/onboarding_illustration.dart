import 'package:flutter/material.dart';

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: 30,
            right: 40,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 50,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 30,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Location pin icon
          Positioned(
            bottom: 120,
            right: 50,
            child: Icon(
              Icons.location_on,
              color: Colors.pink.withOpacity(0.4),
              size: 35,
            ),
          ),
          
          // Heart icons
          Positioned(
            top: 80,
            right: 100,
            child: Icon(
              Icons.favorite,
              color: Colors.orange,
              size: 30,
            ),
          ),
          Positioned(
            top: 90,
            right: 140,
            child: Icon(
              Icons.favorite,
              color: Colors.orange.withOpacity(0.7),
              size: 20,
            ),
          ),
          
          // Checkmark icon
          Positioned(
            bottom: 140,
            left: 60,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.pink,
                size: 20,
              ),
            ),
          ),
          
          // Main content - Phone and people
          Center(
            child: Container(
              width: 280,
              height: 320,
              child: Stack(
                children: [
                  // Phone mockup in center
                  Positioned(
                    top: 40,
                    left: 80,
                    child: Container(
                      width: 120,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1DAF52),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          // Phone notch
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Shopping cart icon on phone
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DAF52),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Lines representing text
                          Container(
                            width: 70,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 50,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Left person (woman with shopping bag)
                  Positioned(
                    top: 60,
                    left: 0,
                    child: Column(
                      children: [
                        // Head
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A574),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            children: [
                              // Hair
                              Positioned(
                                top: 0,
                                left: 5,
                                right: 5,
                                child: Container(
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2B2B2A),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Body
                        Container(
                          width: 50,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DAF52),
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Legs
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B2B2A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 20,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B2B2A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Shopping bags (left bottom)
                  Positioned(
                    bottom: 20,
                    left: 10,
                    child: Row(
                      children: [
                        Container(
                          width: 35,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DAF52),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 5),
                              Container(
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 35,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DAF52).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 5),
                              Container(
                                width: 15,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Right person (man sitting with laptop)
                  Positioned(
                    top: 100,
                    right: 0,
                    child: Column(
                      children: [
                        // Head
                        Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A574),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            children: [
                              // Hair
                              Positioned(
                                top: 0,
                                left: 5,
                                right: 5,
                                child: Container(
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2B2B2A),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Body (sitting position)
                        Container(
                          width: 45,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DAF52),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              // Shopping cart icon on shirt
                              Positioned(
                                top: 15,
                                left: 10,
                                child: Container(
                                  width: 25,
                                  height: 25,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Legs (sitting)
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 35,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B2B2A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 18,
                              height: 35,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B2B2A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Orange platform/ground
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
