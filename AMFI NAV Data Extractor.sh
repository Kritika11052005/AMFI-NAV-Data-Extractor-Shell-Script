#!/bin/bash

# AMFI NAV Data Extractor
# Extracts Scheme Name and Net Asset Value from AMFI NAV data
# Author: Generated for data extraction task
# Date: $(date +%Y-%m-%d)

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
AMFI_URL="https://www.amfiindia.com/spages/NAVAll.txt"
OUTPUT_TSV="amfi_nav_data.tsv"
OUTPUT_JSON="amfi_nav_data.json"
TEMP_FILE="/tmp/amfi_nav_raw.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check dependencies
check_dependencies() {
    local deps=("curl" "awk" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing[*]}"
        echo "Please install missing dependencies:"
        echo "  Ubuntu/Debian: sudo apt-get install curl gawk jq"
        echo "  CentOS/RHEL: sudo yum install curl gawk jq"
        echo "  macOS: brew install curl gawk jq"
        exit 1
    fi
}

# Download AMFI data
download_data() {
    log "Downloading AMFI NAV data from: $AMFI_URL"
    
    if curl -f -s -o "$TEMP_FILE" "$AMFI_URL"; then
        local file_size=$(wc -l < "$TEMP_FILE")
        success "Downloaded $file_size lines of data"
    else
        error "Failed to download data from AMFI"
        exit 1
    fi
}

# Extract data to TSV format
extract_to_tsv() {
    log "Extracting data to TSV format: $OUTPUT_TSV"
    
    # Write TSV header
    echo -e "Scheme_Name\tNet_Asset_Value" > "$OUTPUT_TSV"
    
    # Process the file
    # AMFI format: Scheme Code;ISIN Div Payout/ ISIN Growth;ISIN Div Reinvestment;Scheme Name;Net Asset Value;Date
    awk -F';' '
    BEGIN {
        count = 0
    }
    
    # Skip empty lines and header/footer lines
    /^$/ { next }
    /^Scheme Code/ { next }
    /^Open Ended Schemes/ { next }
    /^Close Ended Schemes/ { next }
    /^Interval Fund Schemes/ { next }
    
    # Process data lines (should have at least 5 fields)
    NF >= 5 {
        # Clean scheme name (remove extra spaces, quotes)
        scheme_name = $4
        gsub(/^[ \t]+|[ \t]+$/, "", scheme_name)  # Trim whitespace
        gsub(/"/, "", scheme_name)                # Remove quotes
        
        # Clean NAV (should be numeric or N.A.)
        nav = $5
        gsub(/^[ \t]+|[ \t]+$/, "", nav)         # Trim whitespace
        
        # Skip if essential fields are empty
        if (scheme_name == "" || nav == "") next
        
        # Replace tabs and newlines in scheme name with spaces
        gsub(/[\t\n\r]/, " ", scheme_name)
        
        # Print TSV format (tab-separated)
        printf "%s\t%s\n", scheme_name, nav
        count++
    }
    
    END {
        print "Processed " count " schemes" > "/dev/stderr"
    }
    ' "$TEMP_FILE" >> "$OUTPUT_TSV"
    
    local record_count=$(tail -n +2 "$OUTPUT_TSV" | wc -l)
    success "Extracted $record_count records to $OUTPUT_TSV"
}

# Convert TSV to JSON format
convert_to_json() {
    log "Converting data to JSON format: $OUTPUT_JSON"
    
    # Convert TSV to JSON using awk and jq
    {
        echo "["
        tail -n +2 "$OUTPUT_TSV" | awk -F'\t' '
        {
            # Escape quotes and backslashes for JSON
            gsub(/"/, "\\\"", $1)
            gsub(/\\/, "\\\\", $1)
            gsub(/"/, "\\\"", $2)
            gsub(/\\/, "\\\\", $2)
            
            if (NR > 1) print ","
            printf "  {\"scheme_name\": \"%s\", \"nav\": \"%s\"}", $1, $2
        }
        END {
            print ""
            print "]"
        }'
    } > "$OUTPUT_JSON"
    
    # Validate JSON
    if jq empty "$OUTPUT_JSON" 2>/dev/null; then
        local json_count=$(jq length "$OUTPUT_JSON")
        success "Created JSON file with $json_count records"
    else
        error "Generated JSON is invalid"
        rm -f "$OUTPUT_JSON"
    fi
}

# Generate summary statistics
generate_summary() {
    log "Generating summary statistics"
    
    local total_schemes=$(tail -n +2 "$OUTPUT_TSV" | wc -l)
    local valid_navs=$(tail -n +2 "$OUTPUT_TSV" | awk -F'\t' '$2 ~ /^[0-9]+\.?[0-9]*$/ { count++ } END { print count+0 }')
    local na_navs=$(tail -n +2 "$OUTPUT_TSV" | awk -F'\t' '$2 == "N.A." { count++ } END { print count+0 }')
    
    echo
    echo "=== EXTRACTION SUMMARY ==="
    echo "Total schemes extracted: $total_schemes"
    echo "Schemes with valid NAV: $valid_navs"
    echo "Schemes with N.A. NAV: $na_navs"
    echo "TSV file: $OUTPUT_TSV ($(du -h "$OUTPUT_TSV" | cut -f1))"
    
    if [[ -f "$OUTPUT_JSON" ]]; then
        echo "JSON file: $OUTPUT_JSON ($(du -h "$OUTPUT_JSON" | cut -f1))"
    fi
    
    echo
    echo "=== SAMPLE DATA ==="
    echo "First 5 records:"
    head -n 6 "$OUTPUT_TSV" | column -t -s $'\t'
}

# Cleanup function
cleanup() {
    if [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
}

# Main execution
main() {
    log "Starting AMFI NAV data extraction"
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Check if we have required tools
    check_dependencies
    
    # Download the data
    download_data
    
    # Extract to TSV
    extract_to_tsv
    
    # Convert to JSON (optional)
    if command -v jq &> /dev/null; then
        convert_to_json
    else
        warn "jq not found, skipping JSON conversion"
    fi
    
    # Show summary
    generate_summary
    
    success "Data extraction completed successfully!"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "AMFI NAV Data Extractor"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --tsv-only     Generate only TSV output"
        echo "  --json-only    Generate only JSON output (requires jq)"
        echo
        echo "Output files:"
        echo "  $OUTPUT_TSV   - Tab-separated values"
        echo "  $OUTPUT_JSON  - JSON format"
        echo
        echo "Data source: $AMFI_URL"
        exit 0
        ;;
    --tsv-only)
        log "TSV-only mode selected"
        check_dependencies
        download_data
        extract_to_tsv
        generate_summary
        exit 0
        ;;
    --json-only)
        if ! command -v jq &> /dev/null; then
            error "jq is required for JSON-only mode"
            exit 1
        fi
        log "JSON-only mode selected"
        check_dependencies
        download_data
        extract_to_tsv  # Still need TSV as intermediate
        convert_to_json
        generate_summary
        exit 0
        ;;
    "")
        # Default behavior - run main
        main
        ;;
    *)
        error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
