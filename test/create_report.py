#!/usr/bin/env python3
"""
Script to run both Dart and C++ tests for anitomy and generate a comparison report.
This identifies test cases where the Dart implementation differs from the C++ original.

Usage:
    python3 test/create_report.py

    or

    ./test/create_report.py

The script will:
1. Run the Dart tests (dart test test/anitomy_test.dart)
2. Run the C++ tests (make && ./anitomy_test in anitomy_original/test/)
3. Parse both outputs to extract test results
4. Compare the results to identify:
   - Regressions: Tests that pass in C++ but fail in Dart
   - Improvements: Tests that fail in C++ but pass in Dart
   - Common failures: Tests that fail in both implementations
5. Generate a detailed report in test/REPORT.md

Requirements:
- Dart SDK installed
- C++ compiler (g++) installed
- Python 3.6 or higher
"""

import subprocess
import re
import os
from pathlib import Path
from typing import Dict, List, Tuple


class TestResult:
    """Container for parsed test results."""

    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.total = 0
        self.success_rate = 0.0
        self.failures: Dict[str, Dict] = {}  # filename -> failure details

    def add_failure(self, filename: str, errors: List[str]):
        """Add a test failure."""
        self.failures[filename] = {"errors": errors}


def run_dart_tests() -> Tuple[bool, str]:
    """Run Dart tests and return success status and output."""
    print("Running Dart tests...")
    try:
        result = subprocess.run(
            ["dart", "test", "test/anitomy_test.dart"],
            cwd=Path(__file__).parent.parent,
            capture_output=True,
            text=True,
            timeout=60,
        )
        return result.returncode == 0, result.stdout + result.stderr
    except Exception as e:
        return False, f"Error running Dart tests: {str(e)}"


def run_cpp_tests() -> Tuple[bool, str]:
    """Run C++ tests and return success status and output."""
    print("Running C++ tests...")
    test_dir = Path(__file__).parent.parent / "anitomy_original" / "test"

    # Build the C++ test if needed
    try:
        subprocess.run(["make"], cwd=test_dir, capture_output=True, check=True)
    except subprocess.CalledProcessError as e:
        return False, f"Error building C++ tests: {e.stderr.decode()}"

    # Run the test
    try:
        result = subprocess.run(
            ["./anitomy_test"], cwd=test_dir, capture_output=True, text=True, timeout=60
        )
        return True, result.stdout + result.stderr
    except Exception as e:
        return False, f"Error running C++ tests: {str(e)}"


def parse_dart_output(output: str) -> TestResult:
    """Parse Dart test output to extract results."""
    result = TestResult()

    # Extract summary statistics
    passed_match = re.search(r"Passed:\s*(\d+)", output)
    failed_match = re.search(r"Failed:\s*(\d+)", output)
    total_match = re.search(r"Total:\s*(\d+)", output)
    rate_match = re.search(r"Success Rate:\s*([\d.]+)%", output)

    if passed_match:
        result.passed = int(passed_match.group(1))
    if failed_match:
        result.failed = int(failed_match.group(1))
    if total_match:
        result.total = int(total_match.group(1))
    if rate_match:
        result.success_rate = float(rate_match.group(1))

    # Parse failures section
    failures_section = re.search(r"Failures:(.*?)(?=\n\n|$)", output, re.DOTALL)
    if failures_section:
        failures_text = failures_section.group(1)

        # Split by numbered entries
        entries = re.split(r"\n\d+\.\s+", failures_text)
        for entry in entries[1:]:  # Skip the first empty split
            lines = entry.strip().split("\n")
            if not lines:
                continue

            filename = lines[0].strip()
            errors = []

            for line in lines[1:]:
                line = line.strip()
                if line:
                    errors.append(line)

            if filename and errors:
                result.add_failure(filename, errors)

    return result


def parse_cpp_output(output: str) -> TestResult:
    """Parse C++ test output to extract results."""
    result = TestResult()

    # Extract summary statistics
    passed_match = re.search(r"Passed:\s*(\d+)", output)
    failed_match = re.search(r"Failed:\s*(\d+)", output)
    total_match = re.search(r"Total:\s*(\d+)", output)
    rate_match = re.search(r"Success Rate:\s*([\d.]+)%", output)

    if passed_match:
        result.passed = int(passed_match.group(1))
    if failed_match:
        result.failed = int(failed_match.group(1))
    if total_match:
        result.total = int(total_match.group(1))
    if rate_match:
        result.success_rate = float(rate_match.group(1))

    # Parse failures section
    failures_section = re.search(r"Failures\s*\n(.*)", output, re.DOTALL)
    if failures_section:
        failures_text = failures_section.group(1)

        # Split by numbered entries
        entries = re.split(r"\n\d+\.\s+", failures_text)
        for entry in entries[1:]:  # Skip the first empty split
            lines = entry.strip().split("\n")
            if not lines:
                continue

            filename = lines[0].strip()
            errors = []

            for line in lines[1:]:
                line = line.strip()
                if line and not line.startswith("make:"):
                    errors.append(line)

            if filename and errors:
                result.add_failure(filename, errors)

    return result


def generate_report(dart_result: TestResult, cpp_result: TestResult) -> str:
    """Generate a markdown report comparing Dart and C++ results."""

    # Find regressions (files that pass in C++ but fail in Dart)
    regressions = []
    for filename in dart_result.failures:
        if filename not in cpp_result.failures:
            regressions.append((filename, dart_result.failures[filename]))

    # Find improvements (files that fail in C++ but pass in Dart)
    improvements = []
    for filename in cpp_result.failures:
        if filename not in dart_result.failures:
            improvements.append((filename, cpp_result.failures[filename]))

    # Find common failures (files that fail in both)
    common_failures = []
    for filename in dart_result.failures:
        if filename in cpp_result.failures:
            common_failures.append(filename)

    # Generate report
    lines = []
    lines.append("# Anitomy Dart Port Test Comparison Report")
    lines.append("")
    lines.append(
        f"Generated: {subprocess.run(['date'], capture_output=True, text=True).stdout.strip()}"
    )
    lines.append("")

    lines.append("## Summary")
    lines.append("")
    lines.append("| Implementation | Passed | Failed | Total | Success Rate |")
    lines.append("|---------------|--------|--------|-------|--------------|")
    lines.append(
        f"| C++ (Original) | {cpp_result.passed} | {cpp_result.failed} | {cpp_result.total} | {cpp_result.success_rate:.2f}% |"
    )
    lines.append(
        f"| Dart (Port) | {dart_result.passed} | {dart_result.failed} | {dart_result.total} | {dart_result.success_rate:.2f}% |"
    )
    lines.append("")

    # Calculate differences
    pass_diff = dart_result.passed - cpp_result.passed
    fail_diff = dart_result.failed - cpp_result.failed
    rate_diff = dart_result.success_rate - cpp_result.success_rate

    lines.append("### Difference")
    lines.append("")
    lines.append(f"- **Passed**: {pass_diff:+d}")
    lines.append(f"- **Failed**: {fail_diff:+d}")
    lines.append(f"- **Success Rate**: {rate_diff:+.2f}%")
    lines.append("")

    # Regressions section
    lines.append("## Regressions")
    lines.append("")
    lines.append(
        f"Test cases that **pass in C++** but **fail in Dart**: {len(regressions)}"
    )
    lines.append("")

    if regressions:
        for i, (filename, failure) in enumerate(regressions, 1):
            lines.append(f"### {i}. {filename}")
            lines.append("")
            for error in failure["errors"]:
                lines.append(f"- {error}")
            lines.append("")
    else:
        lines.append("✅ No regressions found!")
        lines.append("")

    # Improvements section
    lines.append("## Improvements")
    lines.append("")
    lines.append(
        f"Test cases that **fail in C++** but **pass in Dart**: {len(improvements)}"
    )
    lines.append("")

    if improvements:
        for i, (filename, failure) in enumerate(improvements, 1):
            lines.append(f"### {i}. {filename}")
            lines.append("")
            lines.append("C++ errors:")
            lines.append("")
            for error in failure["errors"]:
                lines.append(f"- {error}")
            lines.append("")
    else:
        lines.append("No improvements over C++ implementation.")
        lines.append("")

    # Common failures section
    lines.append("## Common Failures")
    lines.append("")
    lines.append(
        f"Test cases that **fail in both** implementations: {len(common_failures)}"
    )
    lines.append("")

    if common_failures:
        lines.append("<details>")
        lines.append("<summary>Click to expand common failures</summary>")
        lines.append("")
        for i, filename in enumerate(common_failures, 1):
            lines.append(f"### {i}. {filename}")
            lines.append("")

            lines.append("**C++ errors:**")
            lines.append("")
            for error in cpp_result.failures[filename]["errors"]:
                lines.append(f"- {error}")
            lines.append("")

            lines.append("**Dart errors:**")
            lines.append("")
            for error in dart_result.failures[filename]["errors"]:
                lines.append(f"- {error}")
            lines.append("")

        lines.append("</details>")
        lines.append("")
    else:
        lines.append("No common failures.")
        lines.append("")

    return "\n".join(lines)


def main():
    """Main execution function."""
    # Change to project root
    project_root = Path(__file__).parent.parent
    os.chdir(project_root)

    print("=" * 60)
    print("Anitomy Test Comparison Report Generator")
    print("=" * 60)
    print()

    # Run tests
    dart_success, dart_output = run_dart_tests()
    cpp_success, cpp_output = run_cpp_tests()

    # Parse results
    print("\nParsing test results...")
    dart_result = parse_dart_output(dart_output)
    cpp_result = parse_cpp_output(cpp_output)

    print(
        f"\nDart: {dart_result.passed} passed, {dart_result.failed} failed ({dart_result.success_rate:.2f}%)"
    )
    print(
        f"C++:  {cpp_result.passed} passed, {cpp_result.failed} failed ({cpp_result.success_rate:.2f}%)"
    )

    # Generate report
    print("\nGenerating report...")
    report = generate_report(dart_result, cpp_result)

    # Write report to file
    report_path = Path("test/REPORT.md")
    report_path.write_text(report)

    print(f"\n✅ Report generated: {report_path}")
    print(
        f"   - Regressions (C++ pass, Dart fail): {len([f for f in dart_result.failures if f not in cpp_result.failures])}"
    )
    print(
        f"   - Improvements (C++ fail, Dart pass): {len([f for f in cpp_result.failures if f not in dart_result.failures])}"
    )
    print(
        f"   - Common failures: {len([f for f in dart_result.failures if f in cpp_result.failures])}"
    )
    print()


if __name__ == "__main__":
    main()
