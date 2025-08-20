import 'package:flutter/material.dart';
import '../models/sticker_models.dart';

/// Comprehensive sticker library with multiple packs and categories
class StickerLibrary {
  static List<StickerPack> getAllStickerPacks() {
    return [
      _createAnimalsPack(),
      _createShapesPack(),
      _createLettersPack(),
      _createNumbersPack(),
      _createVehiclesPack(),
      _createNaturePack(),
      _createFoodPack(),
      _createEmotionsPack(),
      _createSeasonalPack(),
    ];
  }

  static List<CanvasBackground> getAllBackgrounds() {
    return [
      // Solid colors
      const CanvasBackground(
        id: 'white',
        name: 'White',
        backgroundColor: Colors.white,
        category: 'solid',
      ),
      const CanvasBackground(
        id: 'light_blue',
        name: 'Sky Blue',
        backgroundColor: Color(0xFFE3F2FD),
        category: 'solid',
      ),
      const CanvasBackground(
        id: 'light_green',
        name: 'Mint Green',
        backgroundColor: Color(0xFFE8F5E8),
        category: 'solid',
      ),
      const CanvasBackground(
        id: 'light_pink',
        name: 'Soft Pink',
        backgroundColor: Color(0xFFFCE4EC),
        category: 'solid',
      ),
      const CanvasBackground(
        id: 'light_yellow',
        name: 'Sunny Yellow',
        backgroundColor: Color(0xFFFFFDE7),
        category: 'solid',
      ),
      const CanvasBackground(
        id: 'light_purple',
        name: 'Lavender',
        backgroundColor: Color(0xFFF3E5F5),
        category: 'solid',
      ),
      
      // Gradients
      const CanvasBackground(
        id: 'sunset',
        name: 'Sunset',
        gradient: [Color(0xFFFF9800), Color(0xFFE91E63)],
        category: 'gradient',
      ),
      const CanvasBackground(
        id: 'ocean',
        name: 'Ocean',
        gradient: [Color(0xFF2196F3), Color(0xFF00BCD4)],
        category: 'gradient',
      ),
      const CanvasBackground(
        id: 'forest',
        name: 'Forest',
        gradient: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
        category: 'gradient',
      ),
      const CanvasBackground(
        id: 'rainbow',
        name: 'Rainbow',
        gradient: [
          Color(0xFFE91E63),
          Color(0xFF9C27B0),
          Color(0xFF3F51B5),
          Color(0xFF2196F3),
          Color(0xFF00BCD4),
          Color(0xFF4CAF50),
          Color(0xFFFFEB3B),
          Color(0xFFFF9800),
        ],
        category: 'gradient',
      ),
      
      // Pattern backgrounds (would be actual images in real app)
      const CanvasBackground(
        id: 'stars',
        name: 'Starry Night',
        imagePath: 'assets/backgrounds/stars.png',
        category: 'pattern',
      ),
      const CanvasBackground(
        id: 'grass',
        name: 'Grass Field',
        imagePath: 'assets/backgrounds/grass.png',
        category: 'nature',
      ),
      const CanvasBackground(
        id: 'clouds',
        name: 'Cloudy Sky',
        imagePath: 'assets/backgrounds/clouds.png',
        category: 'nature',
      ),
      const CanvasBackground(
        id: 'beach',
        name: 'Sandy Beach',
        imagePath: 'assets/backgrounds/beach.png',
        category: 'nature',
      ),
    ];
  }

  static StickerPack _createAnimalsPack() {
    return StickerPack(
      id: 'animals',
      name: 'Animal Friends',
      description: 'Cute animals from around the world',
      category: StickerCategory.animals,
      stickers: [
        // Farm animals
        const Sticker(
          id: 'cow',
          name: 'Cow',
          emoji: '🐄',
          category: StickerCategory.animals,
          metadata: {'type': 'farm', 'sound': 'moo'},
        ),
        const Sticker(
          id: 'pig',
          name: 'Pig',
          emoji: '🐷',
          category: StickerCategory.animals,
          metadata: {'type': 'farm', 'sound': 'oink'},
        ),
        const Sticker(
          id: 'chicken',
          name: 'Chicken',
          emoji: '🐔',
          category: StickerCategory.animals,
          metadata: {'type': 'farm', 'sound': 'cluck'},
        ),
        const Sticker(
          id: 'sheep',
          name: 'Sheep',
          emoji: '🐑',
          category: StickerCategory.animals,
          metadata: {'type': 'farm', 'sound': 'baa'},
        ),
        const Sticker(
          id: 'horse',
          name: 'Horse',
          emoji: '🐴',
          category: StickerCategory.animals,
          metadata: {'type': 'farm', 'sound': 'neigh'},
        ),
        
        // Pets
        const Sticker(
          id: 'dog',
          name: 'Dog',
          emoji: '🐶',
          category: StickerCategory.animals,
          metadata: {'type': 'pet', 'sound': 'woof'},
        ),
        const Sticker(
          id: 'cat',
          name: 'Cat',
          emoji: '🐱',
          category: StickerCategory.animals,
          metadata: {'type': 'pet', 'sound': 'meow'},
        ),
        const Sticker(
          id: 'rabbit',
          name: 'Rabbit',
          emoji: '🐰',
          category: StickerCategory.animals,
          metadata: {'type': 'pet', 'sound': 'thump'},
        ),
        const Sticker(
          id: 'hamster',
          name: 'Hamster',
          emoji: '🐹',
          category: StickerCategory.animals,
          metadata: {'type': 'pet', 'sound': 'squeak'},
        ),
        
        // Wild animals
        const Sticker(
          id: 'lion',
          name: 'Lion',
          emoji: '🦁',
          category: StickerCategory.animals,
          metadata: {'type': 'wild', 'sound': 'roar'},
        ),
        const Sticker(
          id: 'elephant',
          name: 'Elephant',
          emoji: '🐘',
          category: StickerCategory.animals,
          metadata: {'type': 'wild', 'sound': 'trumpet'},
        ),
        const Sticker(
          id: 'giraffe',
          name: 'Giraffe',
          emoji: '🦒',
          category: StickerCategory.animals,
          metadata: {'type': 'wild', 'habitat': 'safari'},
        ),
        const Sticker(
          id: 'monkey',
          name: 'Monkey',
          emoji: '🐒',
          category: StickerCategory.animals,
          metadata: {'type': 'wild', 'sound': 'ooh ooh'},
        ),
        const Sticker(
          id: 'bear',
          name: 'Bear',
          emoji: '🐻',
          category: StickerCategory.animals,
          metadata: {'type': 'wild', 'sound': 'growl'},
        ),
        const Sticker(
          id: 'panda',
          name: 'Panda',
          emoji: '🐼',
          category: StickerCategory.animals,
          metadata: {'type': 'wild', 'habitat': 'bamboo forest'},
        ),
        
        // Ocean animals
        const Sticker(
          id: 'fish',
          name: 'Fish',
          emoji: '🐠',
          category: StickerCategory.animals,
          metadata: {'type': 'ocean', 'habitat': 'water'},
        ),
        const Sticker(
          id: 'whale',
          name: 'Whale',
          emoji: '🐋',
          category: StickerCategory.animals,
          metadata: {'type': 'ocean', 'habitat': 'deep sea'},
        ),
        const Sticker(
          id: 'dolphin',
          name: 'Dolphin',
          emoji: '🐬',
          category: StickerCategory.animals,
          metadata: {'type': 'ocean', 'sound': 'click'},
        ),
        const Sticker(
          id: 'octopus',
          name: 'Octopus',
          emoji: '🐙',
          category: StickerCategory.animals,
          metadata: {'type': 'ocean', 'arms': '8'},
        ),
      ],
    );
  }

  static StickerPack _createShapesPack() {
    return StickerPack(
      id: 'shapes',
      name: 'Colorful Shapes',
      description: 'Basic shapes in bright colors',
      category: StickerCategory.shapes,
      stickers: [
        const Sticker(
          id: 'red_circle',
          name: 'Red Circle',
          emoji: '🔴',
          category: StickerCategory.shapes,
          backgroundColor: Colors.red,
          metadata: {'shape': 'circle', 'color': 'red'},
        ),
        const Sticker(
          id: 'blue_circle',
          name: 'Blue Circle',
          emoji: '🔵',
          category: StickerCategory.shapes,
          backgroundColor: Colors.blue,
          metadata: {'shape': 'circle', 'color': 'blue'},
        ),
        const Sticker(
          id: 'yellow_circle',
          name: 'Yellow Circle',
          emoji: '🟡',
          category: StickerCategory.shapes,
          backgroundColor: Colors.yellow,
          metadata: {'shape': 'circle', 'color': 'yellow'},
        ),
        const Sticker(
          id: 'green_circle',
          name: 'Green Circle',
          emoji: '🟢',
          category: StickerCategory.shapes,
          backgroundColor: Colors.green,
          metadata: {'shape': 'circle', 'color': 'green'},
        ),
        const Sticker(
          id: 'orange_circle',
          name: 'Orange Circle',
          emoji: '🟠',
          category: StickerCategory.shapes,
          backgroundColor: Colors.orange,
          metadata: {'shape': 'circle', 'color': 'orange'},
        ),
        const Sticker(
          id: 'purple_circle',
          name: 'Purple Circle',
          emoji: '🟣',
          category: StickerCategory.shapes,
          backgroundColor: Colors.purple,
          metadata: {'shape': 'circle', 'color': 'purple'},
        ),
        const Sticker(
          id: 'black_square',
          name: 'Black Square',
          emoji: '⬛',
          category: StickerCategory.shapes,
          backgroundColor: Colors.black,
          metadata: {'shape': 'square', 'color': 'black'},
        ),
        const Sticker(
          id: 'white_square',
          name: 'White Square',
          emoji: '⬜',
          category: StickerCategory.shapes,
          backgroundColor: Colors.white,
          metadata: {'shape': 'square', 'color': 'white'},
        ),
        const Sticker(
          id: 'heart',
          name: 'Red Heart',
          emoji: '❤️',
          category: StickerCategory.shapes,
          backgroundColor: Colors.red,
          metadata: {'shape': 'heart', 'color': 'red'},
        ),
        const Sticker(
          id: 'star',
          name: 'Yellow Star',
          emoji: '⭐',
          category: StickerCategory.shapes,
          backgroundColor: Colors.yellow,
          metadata: {'shape': 'star', 'color': 'yellow'},
        ),
        const Sticker(
          id: 'diamond',
          name: 'Blue Diamond',
          emoji: '💎',
          category: StickerCategory.shapes,
          backgroundColor: Colors.blue,
          metadata: {'shape': 'diamond', 'color': 'blue'},
        ),
        const Sticker(
          id: 'triangle',
          name: 'Green Triangle',
          emoji: '🔺',
          category: StickerCategory.shapes,
          backgroundColor: Colors.green,
          metadata: {'shape': 'triangle', 'color': 'green'},
        ),
      ],
    );
  }

  static StickerPack _createLettersPack() {
    return StickerPack(
      id: 'letters',
      name: 'Alphabet Fun',
      description: 'Letters A-Z for learning',
      category: StickerCategory.letters,
      stickers: List.generate(26, (index) {
        final letter = String.fromCharCode(65 + index); // A-Z
        return Sticker(
          id: 'letter_${letter.toLowerCase()}',
          name: 'Letter $letter',
          emoji: '🔤',
          category: StickerCategory.letters,
          metadata: {
            'letter': letter,
            'position': index + 1,
            'type': 'uppercase',
          },
        );
      }),
    );
  }

  static StickerPack _createNumbersPack() {
    return StickerPack(
      id: 'numbers',
      name: 'Number Friends',
      description: 'Numbers 0-20 for counting',
      category: StickerCategory.numbers,
      stickers: List.generate(21, (index) {
        final numberEmojis = ['0️⃣', '1️⃣', '2️⃣', '3️⃣', '4️⃣', '5️⃣', '6️⃣', '7️⃣', '8️⃣', '9️⃣', '🔟'];
        final emoji = index < numberEmojis.length ? numberEmojis[index] : '🔢';
        
        return Sticker(
          id: 'number_$index',
          name: 'Number $index',
          emoji: emoji,
          category: StickerCategory.numbers,
          metadata: {
            'number': index,
            'even': index % 2 == 0,
            'type': 'digit',
          },
        );
      }),
    );
  }

  static StickerPack _createVehiclesPack() {
    return StickerPack(
      id: 'vehicles',
      name: 'Transportation',
      description: 'Cars, planes, and more!',
      category: StickerCategory.vehicles,
      stickers: [
        const Sticker(
          id: 'car',
          name: 'Car',
          emoji: '🚗',
          category: StickerCategory.vehicles,
          metadata: {'type': 'land', 'wheels': '4'},
        ),
        const Sticker(
          id: 'truck',
          name: 'Truck',
          emoji: '🚚',
          category: StickerCategory.vehicles,
          metadata: {'type': 'land', 'size': 'big'},
        ),
        const Sticker(
          id: 'bus',
          name: 'Bus',
          emoji: '🚌',
          category: StickerCategory.vehicles,
          metadata: {'type': 'land', 'passengers': 'many'},
        ),
        const Sticker(
          id: 'train',
          name: 'Train',
          emoji: '🚂',
          category: StickerCategory.vehicles,
          metadata: {'type': 'rail', 'sound': 'choo choo'},
        ),
        const Sticker(
          id: 'airplane',
          name: 'Airplane',
          emoji: '✈️',
          category: StickerCategory.vehicles,
          metadata: {'type': 'air', 'flies': true},
        ),
        const Sticker(
          id: 'helicopter',
          name: 'Helicopter',
          emoji: '🚁',
          category: StickerCategory.vehicles,
          metadata: {'type': 'air', 'propeller': true},
        ),
        const Sticker(
          id: 'ship',
          name: 'Ship',
          emoji: '🚢',
          category: StickerCategory.vehicles,
          metadata: {'type': 'water', 'floats': true},
        ),
        const Sticker(
          id: 'boat',
          name: 'Sailboat',
          emoji: '⛵',
          category: StickerCategory.vehicles,
          metadata: {'type': 'water', 'sail': true},
        ),
        const Sticker(
          id: 'bicycle',
          name: 'Bicycle',
          emoji: '🚲',
          category: StickerCategory.vehicles,
          metadata: {'type': 'land', 'pedal': true, 'wheels': '2'},
        ),
        const Sticker(
          id: 'motorcycle',
          name: 'Motorcycle',
          emoji: '🏍️',
          category: StickerCategory.vehicles,
          metadata: {'type': 'land', 'engine': true, 'wheels': '2'},
        ),
        const Sticker(
          id: 'fire_truck',
          name: 'Fire Truck',
          emoji: '🚒',
          category: StickerCategory.vehicles,
          metadata: {'type': 'emergency', 'color': 'red'},
        ),
        const Sticker(
          id: 'police_car',
          name: 'Police Car',
          emoji: '🚓',
          category: StickerCategory.vehicles,
          metadata: {'type': 'emergency', 'sirens': true},
        ),
        const Sticker(
          id: 'ambulance',
          name: 'Ambulance',
          emoji: '🚑',
          category: StickerCategory.vehicles,
          metadata: {'type': 'emergency', 'medical': true},
        ),
        const Sticker(
          id: 'rocket',
          name: 'Rocket',
          emoji: '🚀',
          category: StickerCategory.vehicles,
          metadata: {'type': 'space', 'destination': 'moon'},
        ),
      ],
    );
  }

  static StickerPack _createNaturePack() {
    return StickerPack(
      id: 'nature',
      name: 'Nature Wonders',
      description: 'Trees, flowers, and natural elements',
      category: StickerCategory.nature,
      stickers: [
        const Sticker(
          id: 'tree',
          name: 'Tree',
          emoji: '🌳',
          category: StickerCategory.nature,
          metadata: {'type': 'plant', 'season': 'all'},
        ),
        const Sticker(
          id: 'flower',
          name: 'Flower',
          emoji: '🌸',
          category: StickerCategory.nature,
          metadata: {'type': 'plant', 'season': 'spring'},
        ),
        const Sticker(
          id: 'sunflower',
          name: 'Sunflower',
          emoji: '🌻',
          category: StickerCategory.nature,
          metadata: {'type': 'plant', 'season': 'summer'},
        ),
        const Sticker(
          id: 'rose',
          name: 'Rose',
          emoji: '🌹',
          category: StickerCategory.nature,
          metadata: {'type': 'plant', 'thorns': true},
        ),
        const Sticker(
          id: 'cactus',
          name: 'Cactus',
          emoji: '🌵',
          category: StickerCategory.nature,
          metadata: {'type': 'plant', 'habitat': 'desert'},
        ),
        const Sticker(
          id: 'sun',
          name: 'Sun',
          emoji: '☀️',
          category: StickerCategory.nature,
          metadata: {'type': 'weather', 'hot': true},
        ),
        const Sticker(
          id: 'moon',
          name: 'Moon',
          emoji: '🌙',
          category: StickerCategory.nature,
          metadata: {'type': 'sky', 'time': 'night'},
        ),
        const Sticker(
          id: 'rainbow',
          name: 'Rainbow',
          emoji: '🌈',
          category: StickerCategory.nature,
          metadata: {'type': 'weather', 'colors': '7'},
        ),
        const Sticker(
          id: 'cloud',
          name: 'Cloud',
          emoji: '☁️',
          category: StickerCategory.nature,
          metadata: {'type': 'weather', 'fluffy': true},
        ),
        const Sticker(
          id: 'lightning',
          name: 'Lightning',
          emoji: '⚡',
          category: StickerCategory.nature,
          metadata: {'type': 'weather', 'electric': true},
        ),
        const Sticker(
          id: 'snowflake',
          name: 'Snowflake',
          emoji: '❄️',
          category: StickerCategory.nature,
          metadata: {'type': 'weather', 'season': 'winter'},
        ),
        const Sticker(
          id: 'butterfly',
          name: 'Butterfly',
          emoji: '🦋',
          category: StickerCategory.nature,
          metadata: {'type': 'insect', 'flies': true},
        ),
        const Sticker(
          id: 'bee',
          name: 'Bee',
          emoji: '🐝',
          category: StickerCategory.nature,
          metadata: {'type': 'insect', 'makes': 'honey'},
        ),
        const Sticker(
          id: 'ladybug',
          name: 'Ladybug',
          emoji: '🐞',
          category: StickerCategory.nature,
          metadata: {'type': 'insect', 'spots': true},
        ),
      ],
    );
  }

  static StickerPack _createFoodPack() {
    return StickerPack(
      id: 'food',
      name: 'Yummy Foods',
      description: 'Delicious fruits, vegetables, and treats',
      category: StickerCategory.food,
      stickers: [
        // Fruits
        const Sticker(
          id: 'apple',
          name: 'Apple',
          emoji: '🍎',
          category: StickerCategory.food,
          metadata: {'type': 'fruit', 'color': 'red'},
        ),
        const Sticker(
          id: 'banana',
          name: 'Banana',
          emoji: '🍌',
          category: StickerCategory.food,
          metadata: {'type': 'fruit', 'color': 'yellow'},
        ),
        const Sticker(
          id: 'orange',
          name: 'Orange',
          emoji: '🍊',
          category: StickerCategory.food,
          metadata: {'type': 'fruit', 'vitamin': 'C'},
        ),
        const Sticker(
          id: 'strawberry',
          name: 'Strawberry',
          emoji: '🍓',
          category: StickerCategory.food,
          metadata: {'type': 'fruit', 'seeds_outside': true},
        ),
        const Sticker(
          id: 'grapes',
          name: 'Grapes',
          emoji: '🍇',
          category: StickerCategory.food,
          metadata: {'type': 'fruit', 'bunch': true},
        ),
        const Sticker(
          id: 'watermelon',
          name: 'Watermelon',
          emoji: '🍉',
          category: StickerCategory.food,
          metadata: {'type': 'fruit', 'seeds': 'black'},
        ),
        
        // Vegetables
        const Sticker(
          id: 'carrot',
          name: 'Carrot',
          emoji: '🥕',
          category: StickerCategory.food,
          metadata: {'type': 'vegetable', 'color': 'orange'},
        ),
        const Sticker(
          id: 'broccoli',
          name: 'Broccoli',
          emoji: '🥦',
          category: StickerCategory.food,
          metadata: {'type': 'vegetable', 'color': 'green'},
        ),
        const Sticker(
          id: 'corn',
          name: 'Corn',
          emoji: '🌽',
          category: StickerCategory.food,
          metadata: {'type': 'vegetable', 'kernels': true},
        ),
        
        // Treats
        const Sticker(
          id: 'cake',
          name: 'Birthday Cake',
          emoji: '🎂',
          category: StickerCategory.food,
          metadata: {'type': 'dessert', 'candles': true},
        ),
        const Sticker(
          id: 'cookie',
          name: 'Cookie',
          emoji: '🍪',
          category: StickerCategory.food,
          metadata: {'type': 'dessert', 'sweet': true},
        ),
        const Sticker(
          id: 'ice_cream',
          name: 'Ice Cream',
          emoji: '🍦',
          category: StickerCategory.food,
          metadata: {'type': 'dessert', 'cold': true},
        ),
        const Sticker(
          id: 'pizza',
          name: 'Pizza',
          emoji: '🍕',
          category: StickerCategory.food,
          metadata: {'type': 'meal', 'shape': 'triangle'},
        ),
        const Sticker(
          id: 'hamburger',
          name: 'Hamburger',
          emoji: '🍔',
          category: StickerCategory.food,
          metadata: {'type': 'meal', 'bun': true},
        ),
      ],
    );
  }

  static StickerPack _createEmotionsPack() {
    return StickerPack(
      id: 'emotions',
      name: 'Feelings & Faces',
      description: 'Express emotions and feelings',
      category: StickerCategory.emotions,
      stickers: [
        const Sticker(
          id: 'happy',
          name: 'Happy',
          emoji: '😊',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'happy', 'mood': 'positive'},
        ),
        const Sticker(
          id: 'very_happy',
          name: 'Very Happy',
          emoji: '😄',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'joy', 'mood': 'positive'},
        ),
        const Sticker(
          id: 'laughing',
          name: 'Laughing',
          emoji: '😂',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'laughter', 'mood': 'positive'},
        ),
        const Sticker(
          id: 'sad',
          name: 'Sad',
          emoji: '😢',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'sad', 'mood': 'negative'},
        ),
        const Sticker(
          id: 'angry',
          name: 'Angry',
          emoji: '😠',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'anger', 'mood': 'negative'},
        ),
        const Sticker(
          id: 'surprised',
          name: 'Surprised',
          emoji: '😮',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'surprise', 'mood': 'neutral'},
        ),
        const Sticker(
          id: 'thinking',
          name: 'Thinking',
          emoji: '🤔',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'thoughtful', 'mood': 'neutral'},
        ),
        const Sticker(
          id: 'sleepy',
          name: 'Sleepy',
          emoji: '😴',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'tired', 'mood': 'neutral'},
        ),
        const Sticker(
          id: 'excited',
          name: 'Excited',
          emoji: '🤩',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'excitement', 'mood': 'positive'},
        ),
        const Sticker(
          id: 'love',
          name: 'Love',
          emoji: '😍',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'love', 'mood': 'positive'},
        ),
        const Sticker(
          id: 'confused',
          name: 'Confused',
          emoji: '😕',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'confusion', 'mood': 'neutral'},
        ),
        const Sticker(
          id: 'cool',
          name: 'Cool',
          emoji: '😎',
          category: StickerCategory.emotions,
          metadata: {'emotion': 'cool', 'mood': 'positive'},
        ),
      ],
    );
  }

  static StickerPack _createSeasonalPack() {
    return StickerPack(
      id: 'seasonal',
      name: 'Seasons & Holidays',
      description: 'Seasonal themes and celebrations',
      category: StickerCategory.seasonal,
      stickers: [
        // Spring
        const Sticker(
          id: 'spring_flower',
          name: 'Spring Flower',
          emoji: '🌷',
          category: StickerCategory.seasonal,
          metadata: {'season': 'spring', 'month': 'april'},
        ),
        const Sticker(
          id: 'easter_egg',
          name: 'Easter Egg',
          emoji: '🥚',
          category: StickerCategory.seasonal,
          metadata: {'season': 'spring', 'holiday': 'easter'},
        ),
        
        // Summer
        const Sticker(
          id: 'beach_ball',
          name: 'Beach Ball',
          emoji: '🏖️',
          category: StickerCategory.seasonal,
          metadata: {'season': 'summer', 'activity': 'beach'},
        ),
        const Sticker(
          id: 'sunglasses',
          name: 'Sunglasses',
          emoji: '🕶️',
          category: StickerCategory.seasonal,
          metadata: {'season': 'summer', 'accessory': true},
        ),
        
        // Fall/Autumn
        const Sticker(
          id: 'pumpkin',
          name: 'Pumpkin',
          emoji: '🎃',
          category: StickerCategory.seasonal,
          metadata: {'season': 'fall', 'holiday': 'halloween'},
        ),
        const Sticker(
          id: 'maple_leaf',
          name: 'Maple Leaf',
          emoji: '🍁',
          category: StickerCategory.seasonal,
          metadata: {'season': 'fall', 'color': 'orange'},
        ),
        const Sticker(
          id: 'turkey',
          name: 'Turkey',
          emoji: '🦃',
          category: StickerCategory.seasonal,
          metadata: {'season': 'fall', 'holiday': 'thanksgiving'},
        ),
        
        // Winter
        const Sticker(
          id: 'snowman',
          name: 'Snowman',
          emoji: '⛄',
          category: StickerCategory.seasonal,
          metadata: {'season': 'winter', 'made_of': 'snow'},
        ),
        const Sticker(
          id: 'christmas_tree',
          name: 'Christmas Tree',
          emoji: '🎄',
          category: StickerCategory.seasonal,
          metadata: {'season': 'winter', 'holiday': 'christmas'},
        ),
        const Sticker(
          id: 'present',
          name: 'Present',
          emoji: '🎁',
          category: StickerCategory.seasonal,
          metadata: {'season': 'winter', 'holiday': 'christmas'},
        ),
        const Sticker(
          id: 'candy_cane',
          name: 'Candy Cane',
          emoji: '🍭',
          category: StickerCategory.seasonal,
          metadata: {'season': 'winter', 'holiday': 'christmas'},
        ),
        
        // Other celebrations
        const Sticker(
          id: 'birthday_hat',
          name: 'Party Hat',
          emoji: '🎉',
          category: StickerCategory.seasonal,
          metadata: {'holiday': 'birthday', 'celebration': true},
        ),
        const Sticker(
          id: 'fireworks',
          name: 'Fireworks',
          emoji: '🎆',
          category: StickerCategory.seasonal,
          metadata: {'holiday': 'new_year', 'celebration': true},
        ),
        const Sticker(
          id: 'balloon',
          name: 'Balloon',
          emoji: '🎈',
          category: StickerCategory.seasonal,
          metadata: {'celebration': true, 'floats': true},
        ),
      ],
    );
  }
}