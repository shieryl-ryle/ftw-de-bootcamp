# dlt/pipeline.py
import dlt, pandas as pd
import os
from glob import glob
# Approach 1: Single resource yielding multiple DataFrames
@dlt.resource(name="oulad_grp2")
def oulad_all_files():
    ROOT_DIR = os.path.dirname(__file__)
    STAGING_DIR = os.path.join(ROOT_DIR, "staging", "oulad")
    csv_files = [
        "assessments.csv",
        "courses.csv",
        "studentAssessment.csv",
        "studentInfo.csv",
        "studentRegistration.csv",
        "vle.csv",
        "studentVle.csv"
    ]
    for csv_file in csv_files:
        file_path = os.path.join(STAGING_DIR, csv_file)
        if os.path.exists(file_path):
            df = pd.read_csv(file_path)
            # Add a column to identify the source file
            df['_source_file'] = csv_file.replace('.csv', '')
            yield df
        else:
            print(f"Warning: File {csv_file} not found")
# Approach 2: Separate resources for each file
@dlt.resource(name="assessments")
def assessments():
    ROOT_DIR = os.path.dirname(__file__)
    STAGING_DIR = os.path.join(ROOT_DIR, "staging", "oulad")
    FILE_PATH = os.path.join(STAGING_DIR, "assessments.csv")
    yield pd.read_csv(FILE_PATH)
@dlt.resource(name="courses")
def courses():
    ROOT_DIR = os.path.dirname(__file__)
    STAGING_DIR = os.path.join(ROOT_DIR, "staging", "oulad")
    FILE_PATH = os.path.join(STAGING_DIR, "courses.csv")
    yield pd.read_csv(FILE_PATH)
@dlt.resource(name="student_assessment")
def student_assessment():
    ROOT_DIR = os.path.dirname(__file__)
    STAGING_DIR = os.path.join(ROOT_DIR, "staging", "oulad")
    FILE_PATH = os.path.join(STAGING_DIR, "studentAssessment.csv")
    yield pd.read_csv(FILE_PATH)
@dlt.resource(name="student_info")
def student_info():
    ROOT_DIR = os.path.dirname(__file__)
    STAGING_DIR = os.path.join(ROOT_DIR, "staging", "oulad")
    FILE_PATH = os.path.join(STAGING_DIR, "studentInfo.csv")
    yield pd.read_csv(FILE_PATH)
@dlt.resource(name="student_registration")
def student_registration():
    ROOT_DIR = os.path.dirname(__file__)
    STAGING_DIR = os.path.join(ROOT_DIR, "staging", "oulad")
    FILE_PATH = os.path.join(STAGING_DIR, "studentRegistration.csv")
    yield pd.read_csv(FILE_PATH)
@dlt.resource(name="vle")
def vle():
    ROOT_DIR = os.path.dirname(__file__)
    STAGING_DIR = os.path.join(ROOT_DIR, "staging", "oulad")
    FILE_PATH = os.path.join(STAGING_DIR, "vle.csv")
    yield pd.read_csv(FILE_PATH)

@dlt.resource(name="student_vle")
def student_vle():
    ROOT_DIR = os.path.dirname(__file__)
    STAGING_DIR = os.path.join(ROOT_DIR, "staging", "oulad")
    FILE_PATH = os.path.join(STAGING_DIR, "studentVle.csv")
    yield pd.read_csv(FILE_PATH)
    
# Approach 3: Dynamic file discovery
@dlt.resource(name="oulad_dynamic")
def oulad_dynamic():
    ROOT_DIR = os.path.dirname(__file__)
    STAGING_DIR = os.path.join(ROOT_DIR, "staging", "oulad")
    # Find all CSV files in the directory
    csv_pattern = os.path.join(STAGING_DIR, "*.csv")
    csv_files = glob(csv_pattern)
    for file_path in csv_files:
        df = pd.read_csv(file_path)
        # Add source file information
        filename = os.path.basename(file_path).replace('.csv', '')
        df['_source_file'] = filename
        yield df
def run_approach_1():
    """Single resource, all files combined"""
    p = dlt.pipeline(
        pipeline_name="oulad-pipeline",
        destination="clickhouse",
        dataset_name="GRP2_OULAD",
    )
    print("Fetching and loading all files as one resource...")
    info = p.run(oulad_all_files())
    print("Records loaded:", info)
def run_approach_2():
    """Separate resources for each file"""
    p = dlt.pipeline(
        pipeline_name="oulad-pipeline",
        destination="clickhouse",
        dataset_name="GRP2_OULAD",
    )
    print("Fetching and loading each file as separate resource...")
    info = p.run([
        assessments(),
        courses(),
        student_assessment(),
        student_info(),
        student_registration(),
        vle(),
        student_vle()
    ])
    print("Records loaded:", info)
def run_approach_3():
    """Dynamic file discovery"""
    p = dlt.pipeline(
        pipeline_name="oulad-pipeline",
        destination="clickhouse",
        dataset_name="GRP2_OULAD",
    )
    print("Fetching and loading dynamically discovered files...")
    info = p.run(oulad_dynamic())
    print("Records loaded:", info)

def run_vle_only():
    """Load only the VLE table"""
    p = dlt.pipeline(
        pipeline_name="oulad-pipeline",
        destination="clickhouse",
        dataset_name="GRP2_OULAD",
    )
    print("Loading only VLE table...")
    info = p.run(vle())
    print("Records loaded:", info)

def run_student_vle_only():
    """Load only the Student VLE table"""
    p = dlt.pipeline(
        pipeline_name="oulad-pipeline",
        destination="clickhouse",
        dataset_name="GRP2_OULAD",
    )
    print("Loading only Student VLE table...")
    info = p.run(student_vle())
    print("Records loaded:", info)

if __name__ == "__main__":
    # Choose which approach to use:
    # Option 1: All files as one resource (creates one table)
    # run_approach_1()
    
    # Option 2: Each file as separate resource (creates separate tables)
    run_approach_2()  # <- Use this to load all files including student_vle
    
    # Option 2b: Load only VLE
    # run_vle_only()
    
    # Option 3: Dynamic discovery (creates one table with source file column)
    # run_approach_3()