# AMFI NAV Data Extractor

A shell script to extract Scheme Names and Net Asset Values from AMFI (Association of Mutual Funds in India) daily NAV data.

## Features

- Downloads latest NAV data from AMFI's official source
- Extracts Scheme Name and Net Asset Value
- Outputs data in both TSV (Tab-Separated Values) and JSON formats
- Includes data validation and error handling
- Provides summary statistics
- Colorized output for better readability

## Requirements

- `bash` (version 4.0+)
- `curl` - for downloading data
- `awk` - for text processing
- `jq` - for JSON processing (optional)

### Installation of Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install curl gawk jq
```

**CentOS/RHEL:**
```bash
sudo yum install curl gawk jq
```

**macOS:**
```bash
brew install curl gawk jq
```

## Usage

### Basic Usage
```bash
./extract_amfi_nav.sh
```

This will generate both TSV and JSON files:
- `amfi_nav_data.tsv` - Tab-separated values
- `amfi_nav_data.json` - JSON format

### Command Line Options

```bash
./extract_amfi_nav.sh --help          # Show help
./extract_amfi_nav.sh --tsv-only      # Generate only TSV
./extract_amfi_nav.sh --json-only     # Generate only JSON
```

## Output Formats

### TSV Format (`amfi_nav_data.tsv`)
```
Scheme_Name	Net_Asset_Value
Aditya Birla Sun Life Equity Fund - Growth	150.2345
HDFC Balanced Advantage Fund - Growth	65.7890
ICICI Prudential Bluechip Fund - Growth	89.1234
```

### JSON Format (`amfi_nav_data.json`)
```json
[
  {
    "scheme_name": "Aditya Birla Sun Life Equity Fund - Growth",
    "nav": "150.2345"
  },
  {
    "scheme_name": "HDFC Balanced Advantage Fund - Growth", 
    "nav": "65.7890"
  }
]
```

## Data Source

The script fetches data from AMFI's official NAV file:
`https://www.amfiindia.com/spages/NAVAll.txt`

This file is updated daily and contains NAV data for all mutual fund schemes in India.

## File Structure

The AMFI NAV file has the following format:
```
Scheme Code;ISIN Div Payout;ISIN Growth;ISIN Div Reinvestment;Scheme Name;Net Asset Value;Date
```

The script extracts columns 4 (Scheme Name) and 5 (Net Asset Value).

## Features

- **Error Handling**: Comprehensive error checking and validation
- **Data Cleaning**: Removes extra whitespace, quotes, and invalid entries
- **Progress Logging**: Detailed logging with timestamps and colors
- **Summary Statistics**: Shows count of processed records and file sizes
- **Flexible Output**: Choose between TSV, JSON, or both formats

## TSV vs JSON - When to Use What?

**Use TSV when:**
- Importing data into spreadsheets (Excel, Google Sheets)
- Working with data analysis tools (R, Python pandas)
- Need simple, lightweight format
- Human-readable tabular data

**Use JSON when:**
- Building web applications or APIs
- Need nested/structured data
- Working with JavaScript applications
- Better for programmatic processing

For this mutual fund NAV data, **TSV is recommended** because:
1. The data is naturally tabular
2. Easier to import into analysis tools
3. Smaller file size
4. More readable for financial data

## Sample Output

```
[2024-01-15 10:30:15] Starting AMFI NAV data extraction
[2024-01-15 10:30:16] Downloading AMFI NAV data from: https://www.amfiindia.com/spages/NAVAll.txt
[SUCCESS] Downloaded 45000 lines of data
[2024-01-15 10:30:17] Extracting data to TSV format: amfi_nav_data.tsv
Processed 8500 schemes
[SUCCESS] Extracted 8500 records to amfi_nav_data.tsv
[2024-01-15 10:30:18] Converting data to JSON format: amfi_nav_data.json
[SUCCESS] Created JSON file with 8500 records

=== EXTRACTION SUMMARY ===
Total schemes extracted: 8500
Schemes with valid NAV: 8200
Schemes with N.A. NAV: 300
TSV file: amfi_nav_data.tsv (1.2M)
JSON file: amfi_nav_data.json (2.8M)
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source. Feel free to use and modify as needed.

## Troubleshooting

**Issue**: Script fails with "command not found"
**Solution**: Install missing dependencies using the commands above

**Issue**: Permission denied
**Solution**: Make the script executable: `chmod +x extract_amfi_nav.sh`

**Issue**: Download fails
**Solution**: Check internet connection and AMFI website availability

**Issue**: No data extracted
**Solution**: AMFI may have changed their data format. Check the raw downloaded file.

## Data Update Frequency

AMFI updates the NAV data daily after market hours (usually by 9 PM IST). The script can be run via cron job for automated daily extraction:

```bash
# Add to crontab for daily execution at 10 PM
0 22 * * * /path/to/extract_amfi_nav.sh
```
 
