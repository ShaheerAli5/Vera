import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vera/features/home/presentation/widgets/moment_image_shimmer.dart';

class _ControlledImage extends ImageProvider<_ControlledImage> {
  final stream = _ControlledStream();
  @override
  Future<_ControlledImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(_ControlledImage key, ImageDecoderCallback decode) => stream;
}

class _ControlledStream extends ImageStreamCompleter {
  void complete(ImageInfo info) => setImage(info);
  void fail() => reportError(context: ErrorDescription('test image'), exception: Exception('Unavailable'));
}

void main() {
  testWidgets('shimmer fills the photo until its first frame and then stops', (tester) async {
    final provider = _ControlledImage();
    await tester.pumpWidget(MaterialApp(home: SizedBox(
      width: 343, height: 194,
      child: Image(image: provider, frameBuilder: momentImageLoadingFrame),
    )));
    expect(find.byType(MomentImageShimmer), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MomentImageShimmer), findsOneWidget);
    final image = await tester.runAsync(() => createTestImage(width: 2, height: 2));
    provider.stream.complete(ImageInfo(image: image!));
    await tester.pumpAndSettle();
    expect(find.byType(MomentImageShimmer), findsNothing);
    expect(find.byType(RawImage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('image failure removes shimmer and shows the error fallback', (tester) async {
    final provider = _ControlledImage();
    await tester.pumpWidget(MaterialApp(home: SizedBox(
      width: 343, height: 194,
      child: Image(
        image: provider, frameBuilder: momentImageLoadingFrame,
        errorBuilder: (_, error, stack) => const Text('Image unavailable'),
      ),
    )));
    expect(find.byType(MomentImageShimmer), findsOneWidget);
    provider.stream.fail();
    await tester.pumpAndSettle();
    expect(find.byType(MomentImageShimmer), findsNothing);
    expect(find.text('Image unavailable'), findsOneWidget);
  });

  testWidgets('reduced-motion preference keeps a static placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: SizedBox(width: 343, height: 194, child: MomentImageShimmer()),
    )));
    await tester.pumpAndSettle();
    expect(find.byType(MomentImageShimmer), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
