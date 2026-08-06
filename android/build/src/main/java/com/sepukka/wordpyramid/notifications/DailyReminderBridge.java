package com.sepukka.wordpyramid.notifications;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.work.Data;
import androidx.work.ExistingPeriodicWorkPolicy;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;

import java.util.Calendar;
import java.util.concurrent.TimeUnit;

public final class DailyReminderBridge {
    static final String UNIQUE_WORK_NAME = "word_ascent_daily_reminder";
    static final String KEY_TITLE = "title";
    static final String KEY_BODY = "body";
    static final String KEY_CHANNEL_NAME = "channel_name";
    private static final int PERMISSION_REQUEST_CODE = 7103;

    private DailyReminderBridge() {}

    public static void requestNotificationPermission(Activity activity) {
        if (activity == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return;
        }
        if (activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED) {
            return;
        }
        activity.runOnUiThread(() -> activity.requestPermissions(
                new String[]{Manifest.permission.POST_NOTIFICATIONS},
                PERMISSION_REQUEST_CODE
        ));
    }

    public static void scheduleDailyReminder(
            Context context,
            int hour,
            int minute,
            boolean skipToday,
            String title,
            String body,
            String channelName
    ) {
        if (context == null) {
            return;
        }
        Context appContext = context.getApplicationContext();
        DailyReminderWorker.createNotificationChannel(appContext, channelName);

        Calendar now = Calendar.getInstance();
        Calendar target = Calendar.getInstance();
        target.set(Calendar.HOUR_OF_DAY, hour);
        target.set(Calendar.MINUTE, minute);
        target.set(Calendar.SECOND, 0);
        target.set(Calendar.MILLISECOND, 0);
        if (skipToday || !target.after(now)) {
            target.add(Calendar.DAY_OF_YEAR, 1);
        }

        long initialDelay = Math.max(target.getTimeInMillis() - now.getTimeInMillis(), 0L);
        Data input = new Data.Builder()
                .putString(KEY_TITLE, title)
                .putString(KEY_BODY, body)
                .putString(KEY_CHANNEL_NAME, channelName)
                .build();
        PeriodicWorkRequest request = new PeriodicWorkRequest.Builder(
                DailyReminderWorker.class,
                24,
                TimeUnit.HOURS
        )
                .setInitialDelay(initialDelay, TimeUnit.MILLISECONDS)
                .setInputData(input)
                .build();

        WorkManager.getInstance(appContext).enqueueUniquePeriodicWork(
                UNIQUE_WORK_NAME,
                ExistingPeriodicWorkPolicy.CANCEL_AND_REENQUEUE,
                request
        );
    }

    public static void cancelDailyReminder(Context context) {
        if (context != null) {
            WorkManager.getInstance(context.getApplicationContext())
                    .cancelUniqueWork(UNIQUE_WORK_NAME);
        }
    }
}
