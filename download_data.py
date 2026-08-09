import subprocess
import json

repo = "BrianWeiss1/Finnhub_Stock_Data"


list_cmd = ["gh", "release", "list", "--repo", repo, "--json", "tagName"]
result = subprocess.run(list_cmd, capture_output=True, text=True)


print(json.loads(result.stdout))
for release in json.loads(result.stdout):
    print(release['tagName'])
    subprocess.run([
        "gh", "release", "download", release['tagName'], 
        "--repo", repo, 
        "--pattern", "*", 
        "--dir", f"./downloads/{release['tagName']}"
    ], check=True)

