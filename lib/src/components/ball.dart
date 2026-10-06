import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import 'bat.dart';
import 'brick.dart';
import 'play_area.dart';

class Ball extends PositionComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Ball({
    required this.velocity,
    required super.position,
    required double radius,
    required this.difficultyModifier,
    required this.shape,
  }) : super(
         
         anchor: Anchor.center,
         size: Vector2.all(radius * 2)
       );

  final Vector2 velocity;
  final double difficultyModifier;
  final BallShape shape;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    switch (shape) {
      case BallShape.circle:
        add(CircleHitbox());
        break;

      case BallShape.square:
        add(RectangleHitbox());
        break;

      case BallShape.triangle:
        add(RectangleHitbox());
        break;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = const Color(0xff1e6091)
      ..style = PaintingStyle.fill;

    switch (shape) {
      case BallShape.circle:
        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          size.x / 2,
          paint,
        );
        break;

      case BallShape.square:
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            0,
            size.x,
            size.y,
          ),
          paint,
        );
        break;

      case BallShape.triangle:
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(size.x, 0)
          ..lineTo(size.x / 2, size.y)
          ..close();

        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += velocity * dt;

    final halfSize = size.x / 2;

    // Limite esquerdo
    if (position.x - halfSize <= 0) {
      position.x = halfSize;
      velocity.x = velocity.x.abs();
    }

    // Limite direito
    if (position.x + halfSize >= game.width) {
      position.x = game.width - halfSize;
      velocity.x = -velocity.x.abs();
    }

    // Limite superior
    if (position.y - halfSize <= 0) {
      position.y = halfSize;
      velocity.y = velocity.y.abs();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayArea) {
      if (intersectionPoints.first.y <= 0) {
        velocity.y = -velocity.y;
      } else if (intersectionPoints.first.x <= 0) {
        velocity.x = -velocity.x;
      } else if (intersectionPoints.first.x >= game.width) {
        velocity.x = -velocity.x;
      } else if (intersectionPoints.first.y >= game.height) {
        add(
          RemoveEffect(
            delay: 0.35,
            onComplete: () {                                    // Modify from here
              game.playState = PlayState.gameOver;
            },
          ),
        );                                                      // To here.
      }
    } else if (other is Bat) {
      velocity.y = -velocity.y;
      velocity.x =
          velocity.x +
          (position.x - other.position.x) / other.size.x * game.width * 0.3;
    } else if (other is Brick) {
      if (position.y < other.position.y - other.size.y / 2) {
        velocity.y = -velocity.y;
      } else if (position.y > other.position.y + other.size.y / 2) {
        velocity.y = -velocity.y;
      } else if (position.x < other.position.x) {
        velocity.x = -velocity.x;
      } else if (position.x > other.position.x) {
        velocity.x = -velocity.x;
      }
      velocity.setFrom(velocity * difficultyModifier);
    }

    
  }
}