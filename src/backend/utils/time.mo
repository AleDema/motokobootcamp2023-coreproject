import Time "mo:base/Time";
import Debug "mo:base/Debug";

module TimeUtils {

    public type TF = {
        #minutes;
        #hours;
        #days
    };

    public func secsToNanos(s : Int) : Int { 1_000_000_000 * s };

    public func daysFromEpoch(timestamp : Time.Time) : Int {
        var to_seconds = timestamp / 1_000_000_000;
        var daysPassed = to_seconds / 60 / 60 / 24;
        Debug.print(debug_show (timestamp));
        Debug.print(debug_show (daysPassed));
        return daysPassed
    };

    public func hoursFromEpoch(timestamp : Time.Time) : Int {
        if (timestamp < 1) return 0;
        var hoursPassed = timestamp / 60 / 60 / 1_000_000_000;
        Debug.print(debug_show (timestamp));
        Debug.print(debug_show (hoursPassed));
        return hoursPassed
    };

    public func timeFromEpoc(timestamp : Time.Time, timeframe : TF) : Int {
        let normalize = timestamp / 1_000_000_000;
        switch (timeframe) {
            case (#minutes) normalize / 60;
            case (#hours) normalize / 60 / 60;
            case (#days) normalize / 60 / 60 / 24
        }
    };

    public func timeframeToNanos(n : Time.Time, timeframe : TF) : Int {
        let normalize = n * 1_000_000_000;
        switch (timeframe) {
            case (#minutes) normalize * 60;
            case (#hours) normalize * 60 * 60;
            case (#days) normalize * 60 * 60 * 24
        }
    };

    public func getTimePassed(recent_timestamp : Time.Time, old_timestamp : Time.Time, timeframe : TF) : Int {
        if (old_timestamp == 0) return recent_timestamp;
        timeFromEpoc(recent_timestamp, timeframe) - timeFromEpoc(old_timestamp, timeframe)
    };

}
