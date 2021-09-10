// @dart=2.9
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
//import 'package:webview_flutter/webview_flutter.dart';
//import 'package:flutter_inappwebview/flutter_inappwebview.dart';

//final String mainUrl = "https://sma-csc.itstk.com/saw/ess?TENANTID=716383812";
String mainUrl = "";
/*final Set<JavascriptChannel> jsChannels = [
  JavascriptChannel(
      name: 'postMessage',
      onMessageReceived: (JavascriptMessage message) {
        print('message.message: ${message.message}');
      }),
].toSet();*/

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  /*SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);*/
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => MainView(),
        // When navigating to the "/second" route, build the SecondScreen widget.
        '/second': (context) => MainWebView(),
      }));
}

class MainView extends StatefulWidget {
  @override
  createState() => _MainAppState();
}

class _MainAppState extends State<MainView> with WidgetsBindingObserver {
  BuildContext actualContext;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final myController = TextEditingController();
  bool reading = false;
  bool cameraOn = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    actualContext = context;
    if (!this.reading) {
      this._getDataStored(context, false);
    }
    return SafeArea(
        child: Scaffold(
            resizeToAvoidBottomInset: Platform.isAndroid ? false : true,
            backgroundColor: Colors.black,
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: this.getInputs())),
                  Expanded(child: _buildQrView(context))
                ])));
  }

  _getDataStored(BuildContext context, force) async {
    if (this.reading && !force) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = prefs.getString('url');
    print("Obteniendo: ");
    print(url);
    if (url != null && url.contains(".itstk.com")) {
      print("Abriendo navegador");
      if (this.controller != null) {
        this.controller.pauseCamera();
        this.controller.stopCamera();
        this.controller.dispose();
        this.cameraOn = false;
      }
      this.reading = true;
      mainUrl = url;
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacementNamed(context, '/second');
      });
    }
  }

  _setDataStored(String url) async {
    print("ENTRA");
    this.controller.pauseCamera();
    this.controller.stopCamera();
    this.controller.dispose();
    this.cameraOn = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('url', url);
    mainUrl = url;
    print('SAVED!');
    /*Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/second');
    });*/
    this._getDataStored(this.actualContext, true);
  }

  List<Widget> getInputs() {
    this.myController.text = mainUrl;
    List<Widget> inputs = <Widget>[];
    inputs.add(Container(
        margin: EdgeInsets.only(left: 30, right: 30, top: 5),
        child: TextFormField(
            style: TextStyle(color: Colors.white, fontSize: 12),
            cursorColor: Colors.blueAccent,
            controller: myController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent)),
                focusColor: Colors.blueAccent,
                labelText: "Lee un QR o ingresa una URL",
                hintText: "",
                enabled: true,
                labelStyle: TextStyle(color: Colors.white),
                hintStyle: TextStyle(color: Colors.white)))));
    inputs.add(ElevatedButton(
        onPressed: () {
          String url = this.myController.text;
          if (url != '' && url.contains(".itstk.com")) {
            this.reading = true;
            this._setDataStored(url);
          }
        },
        child: Text('Continuar')));
    return inputs;
  }

  @override
  initState() {
    super.initState();
    //WidgetsBinding.instance.addObserver(this);
  }

  Widget _buildQrView(BuildContext context) {
    if (this.cameraOn) {
      return Container();
    }
    print("HEYYYYYYYYYY");
    this.cameraOn = true;
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: this._onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.blueAccent,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      String url = scanData.code;
      this.myController.text = url;
      if (url != '' && url.contains(".itstk.com")) {
        this.reading = true;
        this._setDataStored(url);
      }
    });
  }

  @override
  void dispose() {
    this.controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print("app in resumed");
        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        break;
      case AppLifecycleState.paused:
        print("app in paused");
        break;
      case AppLifecycleState.detached:
        print("app in detached");

        /*flutterWebViewPlugin.cleanCookies();
        flutterWebViewPlugin.clearCache();
        flutterWebViewPlugin
            .evalJavascript('sessionStorage.clear(); localStorage.clear();');*/
        break;
    }
  }
}

class MainWebView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainWebViewState();
}

class _MainWebViewState extends State<MainWebView> {
  final flutterWebViewPlugin = FlutterWebviewPlugin();

  _MainWebViewState() {
    flutterWebViewPlugin.onStateChanged.listen((viewState)async{
      if(viewState.type==WebViewState.finishLoad){
        print("del if");
        flutterWebViewPlugin.evalJavascript("""
        const time1 = setInterval(() => {
          let el7 = document.querySelector('[data-aid="mobile-promotion-anchor"]');
            if (el7) {
                
                el7.style.display = 'none';
                clearInterval(time1);
            }
        },10)
        """);
      }
    });
    flutterWebViewPlugin.onUrlChanged.listen((String url) {
      print("que visaje");
      if (url.contains('logout?tenant')) {
        flutterWebViewPlugin.cleanCookies();
        flutterWebViewPlugin.clearCache();
        flutterWebViewPlugin
            .evalJavascript('sessionStorage.clear(); localStorage.clear();');

        flutterWebViewPlugin.reloadUrl(mainUrl);
        return;
      }

      flutterWebViewPlugin.evalJavascript("""
        try{
            clearInterval(interval);
        }catch(err){}
        interval = setInterval(() => {
          try{
            let el = document.getElementById('serviceRequest_Creadodesde_c');
            if(el && el.used != 'true') {
              el.disabled = false;
              el.click();
              el.used = 'true';
              el.disabled = true;
            }
            let el2 = document.querySelector('.icon-close-delete-small');
            if(el2) {
              el2.click();
            }
            let el3 = document.querySelector('[data-aid="mobile-app-instructions"]');
            if(el3) {
              el3.style.display = 'none';
            }
            let el4 = document.getElementById('supportRequest_Creadodesde_c');
            if(el4 && el4.used != 'true') {
              el4.disabled = false;
              el4.click();
              el4.used = 'true';
              el4.disabled = true;
            }
            let el5 = document.querySelector('button[data-aid="submit-survey-btn"]');
            if (el5) {
                el5.style.bottom = '2px';
            }
            let el6 = document.getElementsByClassName('survey-thank-you-message');
            if (el6) {
                
                el6[0].style.display = 'none';
                
            }
            
            window.webkit.messageHandlers.iOSNative.postMessage('Working...');
          }catch(err) {}
        }, 1000); 
      """);
    });

    flutterWebViewPlugin.onStateChanged.listen((state) async {
      if (state.type == WebViewState.finishLoad) {
        flutterWebViewPlugin.evalJavascript("""
        try{
            clearInterval(interval);
        }catch(err){}
        interval = setInterval(() => {
          try{
            let el = document.getElementById('serviceRequest_Creadodesde_c');
            if(el && el.used != 'true') {
              el.disabled = false;
              el.click();
              el.used = 'true';
              el.disabled = true;
            }
            let el2 = document.querySelector('.icon-close-delete-small');
            if(el2) {
              el2.click();
            }
            let el3 = document.querySelector('[data-aid="mobile-app-instructions"]');
            if(el3) {
              el3.style.display = 'none';
            }
            let el4 = document.getElementById('supportRequest_Creadodesde_c');
            if(el4 && el4.used != 'true') {
              el4.disabled = false;
              el4.click();
              el4.used = 'true';
              el4.disabled = true;
            }
            let el5 = document.querySelector('button[data-aid="submit-survey-btn"]');
            if (el5) {
               el5.style.bottom = 2px;
            }
            let el6 = document.getElementsByClassName('survey-thank-you-message');
            if (el6) {
                
                el6[0].style.display = 'none';
                
            }
            
            
            window.webkit.messageHandlers.iOSNative.postMessage('Working...');
          }catch(err) {}
        }, 1000); 
      """);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    print("Navegando a: ");
    print(mainUrl);
    return SafeArea(
        maintainBottomViewPadding: true,
        bottom: true,
        child: WebviewScaffold(
            url: mainUrl,
            withJavascript: true,
            withLocalStorage: true,
            userAgent:
                'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Mobile Safari/537.36',
            ignoreSSLErrors: true,
            clearCache: true,
            appCacheEnabled: false,
            clearCookies: true,
            appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.qr_code),
                  color: Colors.white,
                  onPressed: () {
                    this._deleteDataStored(context);
                  },
                ))));
  }

  _deleteDataStored(BuildContext actualContext) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('url');
    Future.delayed(Duration.zero, () {
      // Navigator.pop(actualContext);
      // Navigator.pushNamed(actualContext, '/');
      Navigator.pushReplacementNamed(actualContext, '/');
    });
  }

  @override
  initState() {
    super.initState();
  }
}
