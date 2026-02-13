import Foundation

let checkRateOptions: [(value: Int, label: String)] = [
    (0, "Constant"),
    (30, "30 seconds"),
    (40, "40 seconds"),
    (60, "1 minute"),
    (300, "5 minutes"),
    (900, "15 minutes"),
    (1800, "30 minutes"),
    (3600, "1 hour"),
    (86400, "1 day"),
]

let timeoutOptions = [5, 10, 15, 20, 30, 45, 60, 75]
let triggerRateOptions = [0, 1, 2, 3, 5, 10, 15, 30, 60]
let confirmationRange = 0...3
