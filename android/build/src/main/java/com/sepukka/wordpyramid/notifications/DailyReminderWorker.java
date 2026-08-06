package com.sepukka.wordpyramid.notifications;

import android.Manifest;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

public final class DailyReminderWorker extends Worker {
    private static final String CHANNEL_ID = "word_ascent_daily";
    private static final int NOTIFICATION_ID = 7103;

    public DailyReminderWorker(@NonNull Context context, @NonNull WorkerParameters params) {
        super(context, params);
    }

    @NonNull
    @Override
    public Result doWork() {
        Context context = getApplicationContext();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
                && ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
            return Result.success();
        }

        String title = valueOrFallback(
                getInputData().getString(DailyReminderBridge.KEY_TITLE),
                "Today's ascent is ready!"
        );
        String body = valueOrFallback(
                getInputData().getString(DailyReminderBridge.KEY_BODY),
                "A new Daily Challenge is waiting for you."
        );
        String channelName = valueOrFallback(
                getInputData().getString(DailyReminderBridge.KEY_CHANNEL_NAME),
                "Daily Challenge reminders"
        );
        createNotificationChannel(context, channelName);

        Intent launchIntent = context.getPackageManager()
                .getLaunchIntentForPackage(context.getPackageName());
        if (launchIntent == null) {
            return Result.success();
        }
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                context,
                NOTIFICATION_ID,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        int iconId = context.getResources().getIdentifier(
                "ic_word_ascent_notification",
                "drawable",
                context.getPackageName()
        );
        if (iconId == 0) {
            iconId = context.getApplicationInfo().icon;
        }
        NotificationCompat.Builder notification = new NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(iconId)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent);
        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification.build());
        } catch (SecurityException ignored) {
            // Permission can be revoked after the work was scheduled.
        }
        return Result.success();
    }

    static void createNotificationChannel(Context context, String channelName) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return;
        }
        NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                valueOrFallback(channelName, "Daily Challenge reminders"),
                NotificationManager.IMPORTANCE_DEFAULT
        );
        channel.setDescription("Word Ascent Daily Challenge reminders");
        NotificationManager manager = context.getSystemService(NotificationManager.class);
        if (manager != null) {
            manager.createNotificationChannel(channel);
        }
    }

    private static String valueOrFallback(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value;
    }
}
