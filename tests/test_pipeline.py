from pathlib import Path
import importlib.util
import numpy as np
import pandas as pd
BASE=Path(__file__).resolve().parents[1]
def load(key):
    s=importlib.util.spec_from_file_location(key,BASE/'src/pipeline.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m

def test_loan_current_default_excluded_from_resolved():
    m=load('loans');x=pd.Series(['Fully Paid','Charged Off','Current','Default','Late (31-120 days)','Does not meet the credit policy. Status:Fully Paid'])
    r=list(m.classify_status(x))
    assert r==['Resolved good','Resolved bad','Current','Default','Late / grace','Resolved good']

def test_fresh_pipeline_exports_loadable_dimensions(tmp_path):
    m=load('loans')
    base=dict(id='A',loan_amnt='1000',funded_amnt='1000',term='36 months',int_rate='10',grade='A',sub_grade='A1',issue_d='Jan-2015',loan_status='Fully Paid',annual_inc='60000',dti='12',purpose='credit_card',addr_state='CA',home_ownership='RENT',emp_length='2 years',fico_range_low='680',fico_range_high='684',application_type='Individual',out_prncp='0',total_pymnt='1100',recoveries='0',last_pymnt_d='Jan-2018')
    rows=[base,dict(base,id='B',loan_status='Charged Off'),dict(base,id='C',loan_status='Current',out_prncp='600'),dict(base,id='Footer',issue_d=None,loan_amnt=None)]
    source=tmp_path/'source.csv';pd.DataFrame(rows).to_csv(source,index=False)
    result=m.run(source,tmp_path/'project')
    assert result['n']==3 and result['invalid_rows_excluded']==1
    assert result['resolved']==2 and result['bad']==1
    assert result['bad_resolved_share']==.5
    for table,column in [('grades','Grade'),('states','State'),('purposes','Purpose')]:
        d=pd.read_csv(tmp_path/f'project/data/processed/{table}.csv')
        assert len(d)==1 and d.columns.tolist()==[column]
