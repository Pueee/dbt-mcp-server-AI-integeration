import csv, random, datetime as dt

random.seed(42)
OUT = "/home/claude/dbt_mcp_demo/seeds/"

channels = [
    (1, "Paid Search",      "Search",  "Google Ads"),
    (2, "Paid Social",      "Social",  "Meta"),
    (3, "Programmatic",     "Display", "DV360"),
    (4, "Online Video",     "Video",   "YouTube"),
    (5, "Retail Media",     "Commerce","Amazon Ads"),
]

with open(OUT + "raw_channels.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["channel_id", "channel_name", "channel_group", "platform"])
    w.writerows(channels)

clients = ["Northbank Insurance", "Halden Motors", "Verity Foods", "Kestrel Travel"]
campaigns = []
cid = 1000
for client in clients:
    for ch_id, ch_name, _, _ in channels:
        if random.random() < 0.25:
            continue
        cid += 1
        start = dt.date(2026, 1, 1) + dt.timedelta(days=random.randint(0, 45))
        end = start + dt.timedelta(days=random.choice([60, 90, 120]))
        campaigns.append((
            cid,
            f"{client.split()[0]} {ch_name} Q1",
            client,
            ch_id,
            start.isoformat(),
            end.isoformat(),
            0,  # budget set after spend is generated, so pacing is realistic
            random.choice(["ACTIVE", "ACTIVE", "ACTIVE", "PAUSED", "COMPLETED"]),
        ))

# Daily performance, 1 Feb - 30 Apr 2026
rows = []
day = dt.date(2026, 2, 1)
last = dt.date(2026, 4, 30)
while day <= last:
    for c in campaigns:
        c_start = dt.date.fromisoformat(c[4])
        c_end = dt.date.fromisoformat(c[5])
        if not (c_start <= day <= c_end):
            continue
        if c[7] == "PAUSED" and random.random() < 0.4:
            continue
        base = {1: 48000, 2: 90000, 3: 210000, 4: 130000, 5: 26000}[c[3]]
        weekend = 0.72 if day.weekday() >= 5 else 1.0
        impressions = int(base * weekend * random.uniform(0.65, 1.35))
        ctr = {1: 0.041, 2: 0.011, 3: 0.0016, 4: 0.0055, 5: 0.019}[c[3]]
        clicks = int(impressions * ctr * random.uniform(0.7, 1.3))
        conversions = int(clicks * random.uniform(0.012, 0.058))
        cpm = {1: 4200, 2: 750, 3: 240, 4: 1500, 5: 3100}[c[3]]
        spend_pence = int(impressions / 1000 * cpm * random.uniform(0.85, 1.15))
        # data lands 1-3 days after the event, mirroring a real ad platform feed
        loaded = day + dt.timedelta(days=random.choice([1, 1, 1, 2, 3]))
        rows.append([day.isoformat(), c[0], impressions, clicks, conversions,
                     spend_pence, loaded.isoformat() + " 04:15:00"])
    day += dt.timedelta(days=1)

with open(OUT + "raw_ad_spend.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["event_date", "campaign_id", "impressions", "clicks",
                "conversions", "spend_pence", "loaded_at"])
    w.writerows(rows)

# Budget is set from realised spend so pacing lands in a believable range
spend_by_campaign = {}
for r in rows:
    spend_by_campaign[r[1]] = spend_by_campaign.get(r[1], 0) + r[5] / 100

final = []
for c in campaigns:
    spent = spend_by_campaign.get(c[0], 0)
    pacing = random.uniform(0.42, 0.98)
    budget = max(5000, int(round(spent / pacing, -3)))
    final.append(list(c[:6]) + [budget, c[7]])

with open(OUT + "raw_campaigns.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["campaign_id", "campaign_name", "client_name", "channel_id",
                "start_date", "end_date", "budget_gbp", "status"])
    w.writerows(final)

print("channels:", len(channels), "campaigns:", len(final), "spend rows:", len(rows))
