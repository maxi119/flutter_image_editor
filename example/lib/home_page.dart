import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_editor_example/advanced_page.dart';

import 'const/resource.dart';
import 'package:image_editor/image_editor.dart';

import 'widget/clip_widget.dart';
import 'widget/flip_widget.dart';
import 'widget/rotate_widget.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ImageProvider provider;

  @override
  void initState() {
    super.initState();
    provider = AssetImage(R.ASSETS_ICON_PNG);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Simple usage"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.extension),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AdvancedPage(),
            )),
            tooltip: "Use extended_image library",
          ),
          IconButton(
            icon: Icon(Icons.settings_backup_restore),
            onPressed: restore,
            tooltip: "Restore image to default.",
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: Image(
              image: provider,
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    FlipWidget(
                      onTap: _flip,
                    ),
                    ClipWidget(
                      onTap: _clip,
                    ),
                    RotateWidget(
                      onTap: _rotate,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void setProvider(ImageProvider provider) {
    this.provider = provider;
    setState(() {});
  }

  void restore() {
    setProvider(AssetImage(R.ASSETS_ICON_PNG));
  }

  Future<Uint8List> getAssetImage() async {
    final completer = Completer<Uint8List>();

    final config = createLocalImageConfiguration(context);
    final asset = AssetImage(R.ASSETS_ICON_PNG);
    final key = await asset.obtainKey(config);
    final comp = asset.load(key, ( Uint8List bytes, {int cacheHeight, int cacheWidth } ){
      return ui.instantiateImageCodec( bytes, targetHeight: cacheHeight, targetWidth: cacheWidth );
    } );
    ImageStreamListener listener;
    listener = ImageStreamListener((info, flag) {
      comp.removeListener(listener);
      info.image.toByteData(format: ui.ImageByteFormat.png).then((data) {
        final l = data.buffer.asUint8List();
        completer.complete(l);
      });
    }, onError: (e, s) {
      completer.completeError(e, s);
    });

    comp.addListener(listener);

    asset.resolve(config);

    return completer.future;
  }

  void _flip(FlipOption flipOption) async {
    handleOption([flipOption]);
  }

  _clip(ClipOption clipOpt) async {
    handleOption([clipOpt]);
  }

  void _rotate(RotateOption rotateOpt) async {
    handleOption([rotateOpt]);
  }

  void handleOption(List<Option> options) async {
    ImageEditorOption option = ImageEditorOption();
    for (final o in options) {
      option.addOption(o);
    }

    final assetImage = await getAssetImage();

    final result = await ImageEditor.editImage(
      image: assetImage,
      imageEditorOption: option,
    );

    final img = MemoryImage(result);
    setProvider(img);
  }
}

Widget buildButton(String text, Function onTap) {
  return FlatButton(
    child: Text(text),
    onPressed: onTap,
  );
}
