package studio.chaosmos.kit;

import android.app.Activity;
import android.content.SharedPreferences;

import com.google.android.play.core.appupdate.AppUpdateManager;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.appupdate.AppUpdateOptions;
import com.google.android.play.core.install.model.AppUpdateType;
import com.google.android.play.core.install.model.InstallStatus;
import com.google.android.play.core.install.model.UpdateAvailability;
import com.google.android.play.core.review.ReviewManager;
import com.google.android.play.core.review.ReviewManagerFactory;

/**
 * Google Play's in-app review and in-app updates, for the kit's PlayCore (kit/shell/play_core.gd), which calls
 * these static methods through JavaClassWrapper. Each answer is a state string the game polls, so no Java
 * callback ever has to cross into Godot. Play's tasks report back on the main thread, where the review card
 * and the update dialog are launched from.
 */
public final class PlayCore {
	private static final String PREFS = "studio.chaosmos.kit.play_core";
	private static final String OFFERED_AT = "update_offered_at";
	private static final long DAY = 24L * 60L * 60L * 1000L;

	private static volatile String review = "idle";
	private static volatile String update = "idle";
	private static AppUpdateManager updates;

	private PlayCore() {}

	/** Play's review card: "asking", then "done" once the flow ends, whether or not Play showed it, or "failed". */
	public static void requestReview(final Activity activity) {
		if ("asking".equals(review)) {
			return;
		}
		review = "asking";
		activity.runOnUiThread(() -> {
			final ReviewManager manager = ReviewManagerFactory.create(activity);
			manager.requestReviewFlow().addOnCompleteListener(request -> {
				if (!request.isSuccessful()) {
					review = "failed";
					return;
				}
				manager.launchReviewFlow(activity, request.getResult()).addOnCompleteListener(flow -> review = "done");
			});
		});
	}

	public static String reviewState() {
		return review;
	}

	/**
	 * Offers a flexible update, which downloads while the game goes on, once it has been on Play for staleDays
	 * and at most once every quietDays. An update downloaded earlier and not yet installed is noticed too, and
	 * updateState() becomes "downloaded" when one is ready to install.
	 */
	public static void checkForUpdate(final Activity activity, final int staleDays, final int quietDays) {
		activity.runOnUiThread(() -> {
			if (updates == null) {
				updates = AppUpdateManagerFactory.create(activity);
				updates.registerListener(state -> {
					if (state.installStatus() == InstallStatus.DOWNLOADED) {
						update = "downloaded";
					}
				});
			}
			updates.getAppUpdateInfo().addOnSuccessListener(info -> {
				if (info.installStatus() == InstallStatus.DOWNLOADED) {
					update = "downloaded";
					return;
				}
				Integer stale = info.clientVersionStalenessDays();
				SharedPreferences prefs = activity.getSharedPreferences(PREFS, Activity.MODE_PRIVATE);
				long now = System.currentTimeMillis();
				if (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE
						|| !info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
						|| stale == null || stale < staleDays
						|| now - prefs.getLong(OFFERED_AT, 0L) < quietDays * DAY) {
					return;
				}
				prefs.edit().putLong(OFFERED_AT, now).apply();
				update = "offered";
				updates.startUpdateFlow(info, activity, AppUpdateOptions.defaultOptions(AppUpdateType.FLEXIBLE));
			});
		});
	}

	public static String updateState() {
		return update;
	}

	/** Installs the downloaded update: Play shows its own screen, then the game opens again on the new version. */
	public static void completeUpdate() {
		if (updates != null) {
			updates.completeUpdate();
		}
	}
}
