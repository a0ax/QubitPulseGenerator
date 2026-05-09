from datetime import datetime, timedelta
import random
import subprocess

NAME = b"Alexander Weimer"
EMAIL = b"a0@ieee.org"

random.seed(42)

commits = subprocess.check_output(
    ["git", "rev-list", "--reverse", "--all"]
).decode().splitlines()

weekends = []
day = datetime.now().date()

while len(weekends) < len(commits) // 2 + 10:
    if day.weekday() in (5, 6):
        weekends.append(day)
    day -= timedelta(days=1)

dates = {}
index = 0

for weekend in weekends:
    amount = random.randint(0, 2)

    for _ in range(amount):
        if index >= len(commits):
            break

        dt = datetime(
            weekend.year,
            weekend.month,
            weekend.day,
            random.randint(9, 21),
            random.randint(0, 59),
            random.randint(0, 59),
        )

        dates[commits[index]] = int(dt.timestamp())
        index += 1

while index < len(commits):
    dt = datetime(
        weekends[-1].year,
        weekends[-1].month,
        weekends[-1].day,
        12,
        0,
        0,
    )

    dates[commits[index]] = int(dt.timestamp())
    index += 1


def callback(commit):
    oid = commit.original_id.decode()

    commit.author_name = NAME
    commit.committer_name = NAME

    commit.author_email = EMAIL
    commit.committer_email = EMAIL

    if oid in dates:
        stamp = str(dates[oid]).encode() + b" +0000"
        commit.author_date = stamp
        commit.committer_date = stamp