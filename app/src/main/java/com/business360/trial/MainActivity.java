package com.business360.trial;

import android.annotation.SuppressLint;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.ValueCallback;
import android.net.Uri;
import android.content.Intent;
import android.webkit.JavascriptInterface;
import android.provider.MediaStore;
import android.os.Environment;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.text.TextUtils;
import androidx.core.content.FileProvider;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.TextRecognition;
import com.google.mlkit.vision.text.TextRecognizer;
import com.google.mlkit.vision.text.latin.TextRecognizerOptions;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    private WebView webView;
    private ValueCallback<Uri[]> filePathCallback;
    private static final int STOCK_IMAGE_REQUEST = 2002;
    private Uri pendingCameraUri;

    @SuppressLint("SetJavaScriptEnabled")
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Window window = getWindow();
        window.setStatusBarColor(Color.rgb(6, 104, 238));
        window.setNavigationBarColor(Color.WHITE);
        window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR);

        webView = new WebView(this);
        webView.setBackgroundColor(Color.rgb(6, 104, 238));
        setContentView(webView);

        webView.setFitsSystemWindows(true);
        webView.setOnApplyWindowInsetsListener((v, insets) -> {
            int top = insets.getInsets(WindowInsets.Type.statusBars()).top;
            int bottom = insets.getInsets(WindowInsets.Type.navigationBars()).bottom;
            v.setPadding(0, top, 0, bottom);
            return insets;
        });
        webView.requestApplyInsets();

        WebSettings s = webView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setAllowFileAccess(true);
        s.setAllowContentAccess(true);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        s.setMediaPlaybackRequiresUserGesture(false);

        webView.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (url == null) return false;
                if (url.startsWith("https://wa.me/") || url.startsWith("https://api.whatsapp.com/")) {
                    try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); return true; } catch (Exception ignored) { return false; }
                }
                if (url.startsWith("mailto:")) {
                    try {
                        Intent intent = new Intent(Intent.ACTION_SENDTO, Uri.parse(url));
                        startActivity(intent);
                        return true;
                    } catch (Exception ignored) { return false; }
                }
                if (url.startsWith("http://") || url.startsWith("https://")) return false;
                try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); return true; } catch (Exception ignored) { return false; }
            }
        });
        webView.addJavascriptInterface(new StockImportBridge(), "Business360Stock");
        webView.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (filePathCallback != null) filePathCallback.onReceiveValue(null);
                filePathCallback = callback;
                Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType("image/*");
                startActivityForResult(Intent.createChooser(intent, "Logo নির্বাচন করুন"), 1001);
                return true;
            }
        });
        webView.loadUrl("file:///android_asset/index.html");

        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override public void handleOnBackPressed() {
                if (webView.canGoBack()) webView.goBack(); else finish();
            }
        });
    }

    private void chooseStockImage() {
        Intent gallery = new Intent(Intent.ACTION_GET_CONTENT);
        gallery.addCategory(Intent.CATEGORY_OPENABLE);
        gallery.setType("image/*");

        Intent camera = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        try {
            File dir = new File(getCacheDir(), "images");
            if (!dir.exists()) dir.mkdirs();
            File photo = File.createTempFile("stock_import_", ".jpg", dir);
            pendingCameraUri = FileProvider.getUriForFile(this, getPackageName() + ".fileprovider", photo);
            camera.putExtra(MediaStore.EXTRA_OUTPUT, pendingCameraUri);
            camera.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION | Intent.FLAG_GRANT_READ_URI_PERMISSION);
        } catch (IOException e) {
            pendingCameraUri = null;
            camera = null;
        }

        Intent chooser = new Intent(Intent.ACTION_CHOOSER);
        chooser.putExtra(Intent.EXTRA_INTENT, gallery);
        if (camera != null) chooser.putExtra(Intent.EXTRA_INITIAL_INTENTS, new Intent[]{camera});
        startActivityForResult(chooser, STOCK_IMAGE_REQUEST);
    }

    private void processStockImage(Uri uri) {
        if (uri == null) {
            sendStockOcr("");
            return;
        }
        try {
            InputImage image = InputImage.fromFilePath(this, uri);
            TextRecognizer recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);
            recognizer.process(image)
                .addOnSuccessListener(result -> {
                    sendStockOcr(result.getText());
                    recognizer.close();
                })
                .addOnFailureListener(error -> {
                    sendStockOcr("");
                    recognizer.close();
                });
        } catch (Exception e) {
            sendStockOcr("");
        }
    }

    private void sendStockOcr(String text) {
        final String safe = org.json.JSONObject.quote(text == null ? "" : text);
        runOnUiThread(() -> webView.evaluateJavascript(
            "window.onStockOcrResult && window.onStockOcrResult(" + safe + ")", null));
    }

    private class StockImportBridge {
        @JavascriptInterface public void pickImage() {
            runOnUiThread(() -> chooseStockImage());
        }
    }

    @Override protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == STOCK_IMAGE_REQUEST) {
            Uri uri = null;
            if (resultCode == RESULT_OK && data != null && data.getData() != null) uri = data.getData();
            else if (resultCode == RESULT_OK) uri = pendingCameraUri;
            pendingCameraUri = null;
            processStockImage(uri);
            return;
        }
        if (requestCode == 1001 && filePathCallback != null) {
            Uri[] results = null;
            if (resultCode == RESULT_OK && data != null && data.getData() != null) results = new Uri[]{data.getData()};
            filePathCallback.onReceiveValue(results);
            filePathCallback = null;
        }
    }

    @Override protected void onDestroy() {
        if (webView != null) webView.destroy();
        super.onDestroy();
    }
}
