import pandas as pd
import matplotlib.pyplot as plt

# Step 1: Load the CSV file
df = pd.read_csv("cohort_retention.csv")

# Step 2: Make sure the columns are numbers
df["activated"] = df["activated"].astype(int)
df["month_number"] = df["month_number"].astype(int)
df["active_users"] = df["active_users"].astype(int)

# Step 3: Find the starting size of each group at month 0
cohort_sizes = df[df["month_number"] == 0][["activated", "active_users"]].copy()
cohort_sizes = cohort_sizes.rename(columns={"active_users": "cohort_size"})

# Step 4: Join cohort size back to the main table
df = df.merge(cohort_sizes, on="activated", how="left")

# Step 5: Calculate retention rate
df["retention_rate"] = df["active_users"] / df["cohort_size"]

# Step 6: Sort data for clean plotting
df = df.sort_values(["activated", "month_number"])

# Step 7: Plot the retention curves
plt.figure(figsize=(10, 6))

for group, group_data in df.groupby("activated"):
    if group == 1:
        label = "Activated Users"
    else:
        label = "Non-Activated Users"

    plt.plot(
        group_data["month_number"],
        group_data["retention_rate"],
        marker="o",
        label=label
    )

plt.title("Retention Curve: Activated vs Non-Activated Users")
plt.xlabel("Months Since First Transaction")
plt.ylabel("Retention Rate")
plt.legend()
plt.grid(True)
plt.show()

# ------------------------------
# Activation Rate Bar Chart
# ------------------------------

activation_counts = df[df["month_number"] == 0][["activated", "cohort_size"]]

labels = ["Non-Activated", "Activated"]
values = activation_counts["cohort_size"].values

plt.figure(figsize=(6,4))
plt.bar(labels, values)

plt.title("User Activation Distribution")
plt.ylabel("Number of Users")

plt.show()

# ------------------------------
# Revenue Comparison Chart
# ------------------------------

segments = ["Non-Activated", "Activated"]
ltv_values = [1452.31, 7266.00]

plt.figure(figsize=(6,4))
plt.bar(segments, ltv_values)

plt.title("Average Lifetime Value by User Segment")
plt.ylabel("Average LTV ($)")

plt.show()



plt.figure(figsize=(10,6))

for group, data in df.groupby("activated"):
    
    label = "Activated Users" if group == 1 else "Non-Activated Users"
    
    plt.plot(
        data["month_number"],
        data["retention_rate"],
        marker="o",
        label=label
    )

plt.title("Retention Curve: Activated vs Non-Activated Users")
plt.xlabel("Months Since First Transaction")
plt.ylabel("Retention Rate")
plt.legend()
plt.grid(True)

# Annotation (add insight to the chart)
plt.text(3, 0.37, "Retention plateau ~25–30%", fontsize=10)
plt.ylim(0, 0.5)
plt.show()

segments = ["Non-Activated", "Activated"]
avg_transactions = [3.65, 11.47]

plt.figure(figsize=(6,4))
plt.bar(segments, avg_transactions)

plt.title("Average Transactions by User Segment")
plt.ylabel("Average Number of Transactions")

plt.savefig("transactions_comparison.png", dpi=300, bbox_inches="tight")

plt.show()