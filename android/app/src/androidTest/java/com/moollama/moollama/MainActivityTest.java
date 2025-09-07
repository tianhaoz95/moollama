package com.moollama.moollama;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import org.junit.runner.RunWith;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.leancode.patrol.PatrolTestRunner;

@RunWith(PatrolTestRunner.class)
public class MainActivityTest extends FlutterActivity {
  @Override
  public void configureFlutterEngine(FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}
