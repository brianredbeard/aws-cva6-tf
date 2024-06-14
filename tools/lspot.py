import boto3
import argparse
import pandas as pd
import json
import sys
from datetime import datetime, timedelta


def logger(message, verbose):
    """
    Logs a message to stderr if verbose is True.

    Args:
        message (str): The message to log.
        verbose (bool): If True, the message is logged to stderr.
    """
    if verbose:
        sys.stderr.write(f"{message}\n")


def get_spot_prices(instance_type, regions, verbose):
    """
    Fetches the spot prices for a given instance type across specified regions.

    Args:
        instance_type (str): The type of EC2 instance to check spot prices for.
        regions (list): A list of region names to check.
        verbose (bool): If True, logs additional information to stderr.

    Returns:
        list: A list of dictionaries containing spot price information for each region.
    """
    spot_prices = []
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=1)

    for region in regions:
        regional_client = boto3.client("ec2", region_name=region)
        logger(f"Fetching availability zones for region {region}...", verbose)
        az_response = regional_client.describe_availability_zones()
        azs = [az["ZoneName"] for az in az_response["AvailabilityZones"]]

        logger(f"Fetching spot price history for region {region}...", verbose)
        prices = regional_client.describe_spot_price_history(
            InstanceTypes=[instance_type],
            ProductDescriptions=["Linux/UNIX"],
            StartTime=start_time,
            EndTime=end_time,
        )

        if prices["SpotPriceHistory"]:
            az_prices = {az: "N/A" for az in azs}
            for price in prices["SpotPriceHistory"]:
                az = price["AvailabilityZone"]
                spot_price = float(price["SpotPrice"])
                if az in az_prices:
                    if az_prices[az] == "N/A" or spot_price < az_prices[az]:
                        az_prices[az] = spot_price

            min_spot_price = min(
                az_prices.values(), key=lambda x: x if x != "N/A" else float("inf")
            )
            min_az = next(
                (az for az, price in az_prices.items() if price == min_spot_price),
                "N/A",
            )

            spot_prices.append(
                {
                    "Region": region,
                    "A": az_prices.get(f"{region}a", "N/A"),
                    "B": az_prices.get(f"{region}b", "N/A"),
                    "C": az_prices.get(f"{region}c", "N/A"),
                    "MinSpotPrice": min_spot_price,
                    "MinSpotPriceAZ": min_az,
                }
            )

    return spot_prices


def output_table(spot_prices):
    """
    Outputs the spot prices in a table format.

    Args:
        spot_prices (list): A list of dictionaries containing spot price information.
    """
    df = pd.DataFrame(spot_prices)
    df = df.sort_values(
        by="MinSpotPrice", ascending=True
    )  # Sort by MinSpotPrice in ascending order
    print(df.to_string(index=False))


def output_json(spot_prices):
    """
    Outputs the spot prices in JSON format.

    Args:
        spot_prices (list): A list of dictionaries containing spot price information.
    """
    sorted_prices = sorted(spot_prices, key=lambda x: x["MinSpotPrice"])
    print(json.dumps(sorted_prices, indent=4))


def output_single_lowest(spot_prices, verbose=False):
    """
    Outputs the single lowest cost availability zone.

    Args:
        spot_prices (list): A list of dictionaries containing spot price information.
        verbose (bool): If True, logs additional information to stderr.
    """
    min_price_entry = min(spot_prices, key=lambda x: x["MinSpotPrice"])
    logger(
        f"Region: {min_price_entry['Region']}, AZ: {min_price_entry['MinSpotPriceAZ']}, Price: {min_price_entry['MinSpotPrice']}",
        verbose,
    )
    print(f"{min_price_entry['MinSpotPriceAZ']}")


def main():
    """
    Main function to parse arguments and fetch spot prices.
    """
    parser = argparse.ArgumentParser(
        description="Check AWS EC2 spot prices for a given instance type."
    )
    parser.add_argument(
        "instance_type",
        type=str,
        help="The instance type to check spot prices for (e.g. f1.2xlarge, vt1.3xlarge, inf2.xlarge, p3.8xlarge)",
    )
    parser.add_argument("--json", action="store_true", help="Output in JSON format.")
    parser.add_argument(
        "--table", action="store_true", help="Output in table format (default)."
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose output."
    )
    parser.add_argument(
        "-1",
        "--one",
        action="store_true",
        help="Output the single lowest cost availability zone.",
    )
    parser.add_argument(
        "-r",
        "--region",
        action="append",
        help="Specify regions to check (can be used multiple times).",
    )

    args = parser.parse_args()

    if args.region:
        regions = args.region
    else:
        client = boto3.client("ec2", region_name="us-east-1")
        logger("Fetching regions...", args.verbose)
        response = client.describe_regions()
        regions = [region["RegionName"] for region in response["Regions"]]

    spot_prices = get_spot_prices(args.instance_type, regions, args.verbose)

    if args.one:
        output_single_lowest(spot_prices, args.verbose)
    elif args.json:
        output_json(spot_prices)
    else:
        output_table(spot_prices)


if __name__ == "__main__":
    main()
