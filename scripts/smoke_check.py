"""Public infrastructure check. Contains no lesson solutions."""

import argparse
import json
import os
import time
import uuid
from pathlib import Path
from urllib.request import urlopen

from pyspark.sql import SparkSession, functions as F


def read_json(url):
    with urlopen(url, timeout=10) as response:
        return json.load(response)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--storage", action="store_true")
    parser.add_argument("--history", action="store_true")
    parser.add_argument("--hold-seconds", type=int, default=0)
    args = parser.parse_args()
    if not 0 <= args.hold_seconds <= 120:
        parser.error("hold-seconds must be between 0 and 120")

    run_id = uuid.uuid4().hex[:12]
    output = Path("/workspace/output/stand_smoke") / run_id
    output.mkdir(parents=True, exist_ok=False)
    spark = (SparkSession.builder.appName("stand_smoke_" + run_id)
             .master(os.environ["SPARK_MASTER_URL"])
             .config("spark.driver.host", os.environ["SPARK_DRIVER_HOST"])
             .config("spark.driver.bindAddress", "0.0.0.0").getOrCreate())
    spark.sparkContext.setLogLevel("WARN")
    evidence = {"run_id": run_id, "spark_version": spark.version}
    try:
        sc = spark.sparkContext
        assert sc.master == "spark://spark-incidents-master:7077", sc.master
        expected = [(0, 25), (1, 25), (2, 25), (3, 25)]
        grouped = (spark.range(100).repartition(4)
                   .withColumn("bucket", F.col("id") % 4).groupBy("bucket").count())
        actual = [tuple(r) for r in grouped.orderBy("bucket").collect()]
        assert actual == expected, actual
        application_id = sc.applicationId
        executors = read_json(sc.uiWebUrl + "/api/v1/applications/" + application_id + "/executors")
        active = [e for e in executors if e["id"] != "driver" and e["isActive"]]
        assert len(active) == 2, active

        # Driver and both workers must see exactly the same local output path.
        local_path = str(output / "local_parquet")
        grouped.write.mode("error").parquet(local_path)
        restored = spark.read.parquet(local_path)
        assert [tuple(r) for r in restored.orderBy("bucket").collect()] == expected
        csv = spark.read.option("header", True).csv("/data/csv/intro/orders_intro.csv")
        assert csv.count() == 30

        if args.storage:
            remote_csv = spark.read.option("header", True).csv(
                "s3a://spark-lab/source/csv/intro/orders_intro.csv")
            assert remote_csv.exceptAll(csv).count() == 0
            assert csv.exceptAll(remote_csv).count() == 0
            remote_path = "s3a://spark-lab/output/stand_smoke/" + run_id
            grouped.write.mode("error").parquet(remote_path)
            assert [tuple(r) for r in spark.read.parquet(remote_path)
                    .orderBy("bucket").collect()] == expected
            evidence["s3_read_write_readback"] = "passed"
            evidence["s3_output"] = remote_path

        internal_port = int(sc.uiWebUrl.rsplit(":", 1)[1])
        browser_port = int(os.environ.get("SPARK_UI_EXTERNAL_BASE_PORT", "14040")) + internal_port - 4040
        evidence.update(application_id=application_id, master=sc.master,
                        executors=len(active), local_read_write_readback="passed",
                        csv_rows=30, driver_ui_browser="http://localhost:" + str(browser_port))
        print("LIVE_UI " + evidence["driver_ui_browser"], flush=True)
        print("SMOKE_JSON " + json.dumps(evidence), flush=True)
        if args.hold_seconds:
            time.sleep(args.hold_seconds)
    finally:
        spark.stop()

    if args.history:
        for attempt in range(30):
            apps = read_json("http://spark-incidents-history:18080/api/v1/applications")
            completed = [a for a in apps if a["id"] == application_id
                         and any(t["completed"] for t in a["attempts"])]
            if completed:
                evidence["history_completed_application"] = "passed"
                break
            time.sleep(2)
        else:
            raise AssertionError("History Server did not expose completed " + application_id)

    (output / "evidence.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print("SMOKE CHECK: OK", flush=True)
    print("EVIDENCE " + str(output / "evidence.json"), flush=True)


if __name__ == "__main__":
    main()
