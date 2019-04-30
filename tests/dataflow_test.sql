CREATE OR REPLACE PACKAGE BODY "LCR"."LCR_DATA" 
IS

wmodule varchar2 (30):='lcr_data';
procedure update_lcr_detail(runDate IN DATE default trunc(sysdate))
is
  refDate Date;
begin
                                                                --update_lcr_detail--
                                                                --31.07.2018--
                                                                --��r�ur Atlason--

                                                                /**************************************************

                                                                Fyllir LCR_DETAIL t�fluna me� g�gnum sem eiga vi�
                                                                dagsetningu tveimur bankad�gum � undan 
                                                                inntaksdagsetningunni � stefjuna.
                                                                Ef ekkert er sett inn �� notar h�n daginn � dag sem
                                                                inntaksdagsetningu.

                                                                **************************************************/


--ef vi� f�um ekkert input �� notum vi� t�mann n�na
--s�kjum LBD(LBD(inputDate))

Select
  last_banking_day into refDate 
  from valholl.dim_time_a_v@analytics_vhgquery
  where the_date = ( 
                      select last_banking_day
                      from valholl.dim_time_a_v@analytics_vhgquery
                      where the_date = runDate
                  );


--ey�um g�gnum dagsins, svo vi� s�um ekki a� tv�skrifa
delete from lcr_detail
where the_date = refDate;


--h�r byrjum vi� a� setja inn
insert into lcr_detail

--s�kjum einu sinni og geymum g�gnin fr� v_liquidity
with from_liquidity as (
  select  the_date,
          bs1_l2,
          type_name,
          gl_account,
          cf_m2_on_30d_amt,
          bookvalue,
          subsystem_id,
          currency,
          ssn,
          id,
          ledger,
          domestic_foreign,
          interest_type,
          eur_isk_rate,
          lcr_cat
  from mimir.v_liquidity@analytics_vhgquery
  where the_date = refDate
),

--flokkum lausafj�reignir einstakra gl lykla eftir gjaldeyri
LIQUID_CURRENCY_SORT as (
SELECT the_date,
       lcr_cat, 
       bs1_l2,
       type_name,
       currency,
       ssn,
       CF_M2_ON_30D_AMT,
       CASE
              WHEN currency = 'ISK' THEn cf_m2_on_30d_amt
              ELSE 0
       END cf_m2_on_30d_ISK_amt,
       CASE 
              WHEN currency != 'ISK' THEN CF_M2_ON_30D_AMT
              ELSE 0 
       END CF_M2_ON_30D_FX_AMT
FROM   from_liquidity
where    gl_account IN ('100020',
                      '100500',
                      '100000',
                      '100400',
                      '100070',
                      '200700',
                      '200000',
                      '200400',
                      '200430')
),

--flokkum nostro ( https://www.investopedia.com/terms/n/nostroaccount.asp ) eignir eftir gjaldeyri
--ekki miki� isk en gott a� hafa �a� til a� for�ast allan misskilning

NOSTRO_CURRENCY_SORT as (
SELECT the_date, 
       bs1_l2,
       lcr_cat,
       type_name,
       gl_account, 
       cf_m2_on_30d_amt,
       currency,
       ssn,
       CASE
              WHEN currency = 'ISK' THEN cf_m2_on_30d_amt
              ELSE 0
       END cf_m2_on_30d_ISK_amt,
       CASE 
              WHEN currency != 'ISK' THEN cf_m2_on_30d_amt
              ELSE 0 
       END CF_M2_ON_30D_FX_AMT
FROM   from_liquidity
       --and bs1_l2 in ('Cash and balances with central bank')--,'Bonds and Debt instruments') 
where    gl_account IN ('128750',
                      '110850')
),

--hreinsun � g�gnum sem n�tast til a� meta �lags�tfl��i
DAILY_OUTFLOW_PREP AS (
SELECT 
the_date,
CASE 
              WHEN bs1_l2 = 'Debt issued and other borrowed funds' THEN 'Debt issued'
              WHEN ssn IN ('7010861399', 
                           '6204100200', 
                           '5311061050', 
                           '5110042170', 
                           '4811002240', 
                           '5505003530', 
                           '6112049060', 
                           '5503059920', 
                           '5502079820', 
                           '5008060280', 
                           '5108088510', 
                           '4405989009', 
                           '5608820419', 
                           '6503989049', 
                           '6503989559', 
                           '5402912259', 
                           '4905089960', 
                           '6810861379', 
                           '4203110280', 
                           '4412060110', 
                           '7005081370', 
                           '6602090930', 
                           '4312043120', 
                           '6010090990', 
                           '5705100530', 
                           '6502992999', 
                           '7105100910', 
                           '7105101050', 
                           '6112075220', 
                           '6603091010', 
                           '5806090150', 
                           '4501069760', 
                           '6406039170', 
                           '6702901079', 
                           '9703034030', 
                           '6211042760', 
                           '6609061260', 
                           '4206881219', 
                           '6805109970', 
                           '6210963039' ) THEN ' Slitamedferd'
              WHEN id IN ('522-29-ALLIANZ_CUSTOMER_ACCOUNTS', 
                          '522-14-ALLIANZ_CUSTOMER_ACCOUNTS') THEN 'Corp Operational' 
              ELSE lcr_cat 
       END LCR_cat,
       CASE 
              WHEN ledger = '21' THEN 0 
              WHEN ssn IN ('7010861399', 
                           '6204100200', 
                           '5311061050', 
                           '5110042170', 
                           '4811002240', 
                           '5505003530', 
                           '6112049060', 
                           '5503059920', 
                           '5502079820', 
                           '5008060280', 
                           '5108088510', 
                           '4405989009', 
                           '5608820419', 
                           '6503989049', 
                           '6503989559', 
                           '5402912259', 
                           '4905089960', 
                           '6810861379', 
                           '4203110280', 
                           '4412060110', 
                           '7005081370', 
                           '6602090930', 
                           '4312043120', 
                           '6010090990', 
                           '5705100530', 
                           '6502992999', 
                           '7105100910', 
                           '7105101050', 
                           '6112075220', 
                           '6603091010', 
                           '5806090150', 
                           '4501069760', 
                           '6406039170', 
                           '6702901079', 
                           '9703034030', 
                           '6211042760', 
                           '6609061260', 
                           '4206881219', 
                           '6805109970', 
                           '6210963039') THEN 1 
              WHEN ( 
                            lcr_cat IN ('Individual',
                                        'SME') 
                     AND    type_name IN ('Vaxta�rep 30 dagar')) THEN 1
              WHEN ( 
                            lcr_cat IN ('Individual',
                                        'SME') 
                     AND    interest_type = '44') THEN 1
              WHEN ( 
                            lcr_cat IN ('Individual',
                                        'SME') 
                     AND    domestic_foreign = 'DOM') THEN 0.0917
              WHEN ( 
                            lcr_cat IN ('Individual',
                                        'SME') 
                     AND    domestic_foreign != 'DOM') THEN 0.2
              WHEN id IN ('522-29-ALLIANZ_CUSTOMER_ACCOUNTS', 
                          '522-14-ALLIANZ_CUSTOMER_ACCOUNTS') THEN 0.25 
              WHEN lcr_cat IN ('Corp.', 
                               'Public institution') THEN 0.3985
              ELSE 1 
       END LCR_weight,
--h�r aggregerum vi� einstaklinga, sem og opinberar stofnanir
CASE
  WHEN LCR_CAT = 'Individual' 
  THEN 'Individual Stuff'
  WHEN LCR_CAT = 'SME'
  THEN 'SME Stuff'
  WHEN LCR_CAT = 'Public institution'
  THEN 'Public inst Stuff'
  ELSE TYPE_NAME
END TYPE_NAME,
BS1_L2,
CURRENCY,
--h�r aggregerum vi� einstaklinga, sem og opinberar stofnanir
CASE
  WHEN LCR_CAT = 'Public institution' 
  THEN '7777777777'
  WHEN LCR_CAT = 'Individual' 
  THEN '8888888888'
  WHEN LCR_CAT = 'SME'
  THEN '9999999999'
  ELSE SSN
END SSN,
--Bookvalue measure-i� s�kir laust f� se skr�ist ekki � cf � AH
CASE 
      WHEN subsystem_id ='AH' THEN Bookvalue
      ELSE cf_m2_on_30d_amt 
END CF_M2_ON_30D_amt,
CASE
      WHEN (currency = 'ISK' AND subsystem_id = 'AH') THEN bookvalue
      WHEN currency = 'ISK' THEn cf_m2_on_30d_amt
      ELSE 0
END cf_m2_on_30d_ISK_amt,
CASE 
      WHEN ( currency != 'ISK' AND subsystem_id ='AH') THEN bookvalue
      WHEN currency != 'ISK' THEN cf_m2_on_30d_amt
      ELSE 0 
END CF_M2_ON_30D_FX_AMT
FROM from_liquidity
WHERE    bs1_l2 IN ('Deposits from Credit Institutions',
                  'Deposits from customers', 
                  'Debt issued and other borrowed funds')--,'Bonds and Debt instruments') 
),

--flokkum og gr�ppum saman High Quality Liquid Assets
--�eas eignir, sem au�velt er a� breyta � lausaf�
HQLA AS (

SELECT the_date,
       'HQLA' as lcr_element,
       lcr_cat,
       bs1_l2,
       type_name,
       null as idx, --idx
       null as idx_name, --idx_name
       currency,
       ssn,
       sum(cf_m2_on_30d_amt) as amt,
       sum(cf_m2_on_30d_ISK_amt) as isk_amt,
       sum(cf_m2_on_30d_fx_amt) as fx_amt 
FROM   LIQUID_CURRENCY_SORT
group by
      the_date,
      lcr_cat,
      type_name,
      bs1_l2,
      currency,
      ssn

UNION ALL

--Trygginar sem vi� geymum fyrir "Cover Bond" br�fin okkar. 
--Cover Bond: Skuldabr�f sem vi� gefum �t � marka� � bak vi� br�fin er r�mleg eing. 
--En vi� ver�um a� hafa sm� cash on hand til a� eiga fyrir �essum br�fum.
--B�inn var til AH reikningur 515115-15-125-1245 til a� halda utan um �etta.

SELECT t.the_date, 
       'HQLA' AS LCR_ELEMENT, --LCR_ELEMENT
       'N/A' as LCR_CAT, --LCR_CAT
       'Cover Bond Tryggingar' AS BS1_L2, -- bs1_l2
       lt.type_name, --TYPE_NAME
       null as idx,
       null as idx_type,
       'ISK' as currency,
       null as ssn,
       -1*(t.exposure) as amt,     -- m�tti l�ka nota:        1*(t.w1 + t.w2 + t.w3 + t.w4 + t.d28 + t.d29 + t.d30 + t.accrued_interest),
       -1*(t.exposure) as isk_amt, -- m�tti l�ka nota:        1*(t.w1 + t.w2 + t.w3 + t.w4 + t.d28 + t.d29 + t.d30 + t.accrued_interest),
       0 as fx_amt --FX_AMT
FROM   valholl.agg_cf_timebuckets_a_v@analytics_vhgquery t,
       valholl.dim_loan_type_a_v@analytics_vhgquery lt
WHERE  1=1 
AND    t.the_date = refDate
AND    t.dim_loan_type = lt.dimension_key 
AND    t.asset_liability = 'l' 
AND    t.deal_id = '500-22-230049' 
AND    t.active != 'N' 
AND    t.payment_type = 'installment'

/*
UNION ALL

select 
  refDate,
  'HQLA' as LCR_ELEMENT,
  'N/A', -- LCR_CAT
  'Onnur statisk binding', --bs1_l2
  'N/A', --type_name
   null as idx, --idx
   null as idx_type, --idx_name
  'ISK', --currency
  null as ssn, --ssn
  -2200000000,  --amt 2.2 ma.
  -2200000000,  --isk_amt 2.2 ma.
  0 --fx_amt
from dual   
*/

UNION ALL
--f�st tala, sem geymist hvergi nema hj� Halla
--fastar, sem vi� erum skyldug til a� geyma og megum ekki telja sem laust f�

select 
  refDate,
  'HQLA' as LCR_ELEMENT,
  'N/A', -- LCR_CAT
  'Bundid hja SI - Halli', --bs1_l2
  'N/A', --type_name
   null as idx, --idx
   null as idx_name, --idx_name
  'ISK', --currency
  NULL as ssn, --ssn
  -4800000000,  --amt 4.8 ma.
  -4800000000, --isk_amt 4.8 ma.
  0 --fx_amt
from dual

---�nnur f�st tala sem tengist bindiskyldu

),

--Fixed � vi� um allar ��r st�r�ir sem koma �r lcr_results_report fr�
--vikulegum uppf�rslum Hauks
fixed as (
--�etta er ���gilegt mix �v� �etta er ekki � sama formi og annar d�teill
--sem kemur �r v_liquidity
SELECT refDate,
       'Fixed' AS LCR_ELEMENT,
       'N/A Static' as lcr_cat,
       'N/A Static' as bs1_l2,
       'N/A Static' as type_name,
       idx, 
       idx_name,
       currency_type as currency,
       null as ssn,
       --NB currency flokkunin er l�ka � ��ru formi h�r en annars sta�ar � stefjunni
       CASE 
              WHEN currency_type = 'total' THEN weighted_amt
              ELSE 0 
       END amt,
       CASE 
              WHEN currency_type = 'ISK' THEN weighted_amt
              ELSE 0 
       END isk_amt, 
       CASE 
              WHEN currency_type = 'FX' THEN weighted_amt
              ELSE 0 
       END fx_amt 
FROM   haukurg.lcr_results_report 
WHERE  the_date = ( 
                    SELECT Max(the_date) 
                    FROM   haukurg.lcr_results_report 
                    WHERE  the_date <= refDate
                  )
AND    idx IN ( '11',
  '13', 
  '14',
  '15',
  '19-c',
  '20'
  ) 
AND    parent_group = 'parent' 
),


--flokkum og gr�ppum saman Nostro
--�eas eignir, sem liggja � ��rum b�nkum � �eirra gjaldeyri
NOSTRO AS(
SELECT the_date,
       'Nostro' as lcr_element,
       lcr_cat,
       bs1_l2,
       type_name,
       null as idx, --idx
       null as idx_name, --idx_name
       currency,
       ssn,
       sum( cf_m2_on_30d_amt ) as amt,
       sum( cf_m2_on_30d_isk_amt ) as isk_amt, 
       sum( cf_m2_on_30d_fx_amt ) as fx_amt 

FROM   NOSTRO_CURRENCY_SORT
group by
      the_date,
      lcr_cat,
      bs1_l2,
      type_name,
      currency,
      ssn
),

DAILY_OUTFLOW as (
SELECT
      the_date,
       'Daily Outflow' as lcr_element,
       lcr_cat,
       bs1_l2,
       type_name,
       null as idx, 
       null as idx_name, 
       currency,
       ssn,
       sum( LCR_weight * cf_m2_on_30d_amt ) as amt,
       sum( LCR_weight * cf_m2_on_30d_isk_amt ) as isk_amt, 
       sum( LCR_weight * cf_m2_on_30d_fx_amt ) as fx_amt
FROM DAILY_OUTFLOW_PREP
GROUP BY
  the_date,
  lcr_cat,
  bs1_l2,
  type_name,
  currency,
  ssn
)

--sameinum a� lokum allar undirfyrirspurnirnar

select * from HQLA

union all 

select * from nostro

union all

select * from DAILY_OUTFLOW

union all

select * from fixed;

commit;

end update_lcr_detail;

-----------------------------------------------------------------------

procedure populate_LCR_ABYRGDIR(inLoadDate in date)
is
  gprogram       VARCHAR2(30)  := 'populate_LCR_ABYRGDIR';
  timestampStart TIMESTAMP     := SYSTIMESTAMP;
  logMessage     VARCHAR2(2000) := 'Processing day: ' || inLoadDate;
  rowsDeleted    NUMBER        := 0;
  rowsInserted   NUMBER        := 0;
begin
  LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,NULL,NULL,NULL,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'START',logMessage,NULL);

  delete from LCR_ABYRGDIR where validdate = inLoadDate;
  rowsDeleted := SQL%ROWCOUNT;
  LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,NULL,NULL,rowsDeleted,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'INFO',logMessage,NULL);
  insert into LCR_ABYRGDIR 
  (
    VALIDDATE, CURRENCY, SUBSYSTEM_NAME, LOAN_BALANCE_ISK
  )
  SELECT 
    bal.the_date validdate, 
    decode(l.currency, 'ISK', 'ISK','EUR','EUR','USD','USD','ANNAD') currency, 
    lt.subsystem_name,
    sum(bal.loan_balance_isk) loan_balance_isk
   FROM valholl.fct_loan_balance_a_v@risk_vhgquery bal,
         valholl.dim_loan_type_a_v@risk_vhgquery lt,
         valholl.dim_loan_a_v@risk_vhgquery l,
         valholl.dim_currency_a_v@risk_vhgquery cu,
         valholl.dim_customer_a_v@risk_vhgquery c
         join valholl.dim_gl_account_a_v@risk_vhgquery ak 
            on bal.dim_gl_account = ak.dimension_key
   WHERE bal.dim_loan_type = lt.dimension_key
     AND bal.the_date = inLoadDate
     AND l.dimension_key = bal.dim_loan
     AND cu.dimension_key = bal.dim_currency
     AND bal.dim_customer = c.dimension_key 
     AND lt.subsystem_id in ('TF')
     and c.internal_ssn != 'U'
     group by bal.the_date, lt.subsystem_name, l.currency
  ;

  rowsInserted := SQL%ROWCOUNT;
  LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,rowsInserted,NULL,rowsDeleted,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'END',logMessage,NULL);
  commit;

  exception when others then
    begin
      LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,NULL,NULL,rowsDeleted,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'ERROR',logMessage || ' - ' || DBMS_UTILITY.format_error_backtrace ,NULL);
      rollback;
      raise;
    end;

end;

procedure populate_LCR_CASH(inLoadDate in date)
is
  gprogram       VARCHAR2(30)  := 'populate_LCR_CASH';
  timestampStart TIMESTAMP     := SYSTIMESTAMP;
  logMessage     VARCHAR2(2000) := 'Processing day: ' || inLoadDate;
  rowsDeleted    NUMBER        := 0;
  rowsInserted   NUMBER        := 0;
begin
  LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,NULL,NULL,NULL,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'START',logMessage,NULL);

  delete from LCR_CASH where validdate = inLoadDate;
  rowsDeleted := SQL%ROWCOUNT;
  LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,NULL,NULL,rowsDeleted,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'INFO',logMessage,NULL);
  insert into LCR_CASH 
  (
    VALIDDATE, ASSLIB, CURRENCY_TYPE, ACCOUNT_NAME, ACCOUNT, PRODUCT, LOAN_IDENTITY, 
    BRANCH, OBLIGOR_TYPE, KT, CPTY, FX_BORROWER, MYNT_TYPE, BALANCE, BALANCE_ISK, EXPOSURE
  )
  SELECT 
    t.the_date validdate,UPPER (bal.asset_liability_exp) asslib,l.currency_type, ak.account_name, ak.account,
  lt.type_id product, l.ID loan_identity, l.branch_id branch,
  c.obligor_type, c.cust_ssn kt, c.cust_full_name cpty,nvl(c.fx_borrower,0) fx_borrower,
  DECODE(l.currency, 'ISK', 'ISK','EUR','EUR','USD','USD','ANNAD') mynt_type,
  DECODE(bal.asset_liability_exp, 'l', -bal.loan_balance,     bal.loan_balance     ) balance,
  DECODE(bal.asset_liability_exp, 'l', -bal.loan_balance_isk, bal.loan_balance_isk ) balance_isk, 
  bal.exposure     
  FROM valholl.fct_loan_balance_a_v@risk_vhgquery bal,
       valholl.dim_time_a_v@risk_vhgquery t,
       valholl.dim_loan_type_a_v@risk_vhgquery lt,
       valholl.dim_loan_a_v@risk_vhgquery l,
       valholl.dim_currency_a_v@risk_vhgquery cu,
       valholl.dim_customer_a_v@risk_vhgquery c,
       valholl.dim_gl_account_a_v@risk_vhgquery ak
   WHERE bal.dim_time = t.dimension_key
     AND bal.dim_loan_type = lt.dimension_key
     AND t.the_date = inLoadDate
     AND l.dimension_key = bal.dim_loan
     AND cu.dimension_key = bal.dim_currency
     AND bal.dim_customer = c.dimension_key
     and bal.dim_gl_account = ak.dimension_key
     AND lt.subsystem_id in ('SJODIR','ATM')
  ;

  rowsInserted := SQL%ROWCOUNT;
  LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,rowsInserted,NULL,rowsDeleted,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'END',logMessage,NULL);
  commit;

  exception when others then
    begin
      LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,NULL,NULL,rowsDeleted,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'ERROR',logMessage || ' - ' || DBMS_UTILITY.format_error_backtrace ,NULL);
      rollback;
      raise;
    end;

end;


-----------------------------------------------------------------------
procedure populate_LCR_HQLA(inLoadDate in date)
is
  gprogram       VARCHAR2(30)  := 'populate_LCR_HQLA';
  timestampStart TIMESTAMP     := SYSTIMESTAMP;
  logMessage     VARCHAR2(2000) := 'Processing day: ' || inLoadDate;
  rowsDeleted    NUMBER        := 0;
  rowsInserted   NUMBER        := 0;
begin
  LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,NULL,NULL,NULL,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'START',logMessage,NULL);

  delete from LCR_HQLA where THE_DATE = inLoadDate;
  rowsDeleted := SQL%ROWCOUNT;
  LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,NULL,NULL,rowsDeleted,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'INFO',logMessage,NULL);
  insert into LCR_HQLA 
  (
    THE_DATE, LCR_SI_CAT, LCR_EBA_CAT, ISK_AMT, EUR_AMT, USD_AMT, ANNAD_AMT
  )

  --Sj??ur
  select 
    the_date,  LCR_SI_CAT, LCR_EBA_CAT, 
    sum(Exposure_ISK) ISK_AMT, 
    sum(Exposure_EUR) EUR_AMT, 
    sum(Exposure_USD) USD_AMT, 
    sum(Exposure_ANNAD) ANNAD_AMT
  from (
  select ValidDate as the_date, mynt_type, 
  case when Product in ( 'SJODIR','ATM') then 'HQLA 1' end LCR_SI_CAT,
  case when Product in ( 'SJODIR','ATM') then '040' end LCR_EBA_CAT,
  case when mynt_type = 'ISK' then exposure else 0 end Exposure_ISK,
  case when mynt_type = 'EUR' then exposure else 0 end Exposure_EUR,
  case when mynt_type = 'USD' then exposure else 0 end Exposure_USD,
  case when mynt_type = 'ANNAD' then exposure else 0 end Exposure_ANNAD
  from LCR.LCR_CASH
  where ValidDate = inLoadDate
  ) group by the_Date,  LCR_SI_CAT, LCR_EBA_CAT

  UNION ALL
    
  --Innst??ur og anna? fr? S?
  select 
    the_date,  LCR_SI_CAT, LCR_EBA_CAT, 
    sum(Exposure_ISK) ISK_AMT, 
    sum(Exposure_EUR) EUR_AMT, 
    sum(Exposure_USD) USD_AMT, 
    sum(Exposure_ANNAD) ANNAD_AMT
  from (
  select ValidDate as the_date, currency, 
  case when LOAN_IDENTITY in ( 'CENREY') then 'HQLA 2' 
  when LOAN_IDENTITY in ( 'CENREYRESV_F') then 'OUTFLOW 58'
  when LOAN_IDENTITY in ( '500152-CBI2016') then 'HQLA 13'
  when LOAN_IDENTITY in ( '500-22-230049') then 'PLEDGED'
  when product = 'IAM' then 'HQLA 3.1'
  when product = 'RepoDeals' then 'HQLA 2'
  else 'Oflokkad'
  end LCR_SI_CAT,
  case when LOAN_IDENTITY in ( 'CENREY') then '050' 
  when LOAN_IDENTITY in ( '500-22-230049') then '060'
  when product = 'IAM' then '060'
  when product = 'RepoDeals' then '060'
  else 'Oflokkad'
  end LCR_EBA_CAT,
  case when currency = 'ISK' then exposure else 0 end Exposure_ISK,
  case when currency = 'EUR' then exposure else 0 end Exposure_EUR,
  case when currency = 'USD' then exposure else 0 end Exposure_USD,
  case when currency = 'ANNAD' then exposure else 0 end Exposure_ANNAD
  from LCR.LCR_utlan_si
  where ValidDate = inLoadDate
  ) group by the_Date,  LCR_SI_CAT, LCR_EBA_CAT

  UNION ALL
  select inLoadDate as the_date, 'PLEDGED' LCR_SI_CAT, '060' LCR_EBA_CAT, case when currency = 'ISK' then amount else 0 end Exposure_ISK,
  case when currency = 'EUR' then amount else 0 end Exposure_EUR,
  case when currency = 'USD' then amount else 0 end Exposure_USD,
  case when currency = 'ANNAD' then amount else 0 end Exposure_ANNAD
  from LCR.LCR_BUNDID_SI 
  where valid_from <= inLoadDate
  and valid_to >= inLoadDate
  union all 

  --Erlend r?kisskuldabr?f --isgogn
  select 
    the_date, LCR_SI_CAT, LCR_EBA_CAT, 
    round(sum(Exposure_ISK),0) ISK_AMT, 
    round(sum(Exposure_EUR),0) EUR_AMT, 
    round(sum(Exposure_USD),0) USD_AMT, 
    round(sum(Exposure_ANNAD),0) ANNAD_AMT
  from (
  select execdate the_date, cur_lcr,
  case when folder in ('LIQUIDITY2') then 'HQLA 4' 
  when Bond like ('ARION_CB%') then 'HQLA 11'
  when Bond like ('LBANK_CB%') then 'HQLA 11'
  else 'Oflokkad'
  end LCR_SI_CAT, 
  case when folder in ('LIQUIDITY2') then '070' 
  --when Bond like ('ARION_CB%') then '320'
  --when Bond like ('LBANK_CB%') then '320'
  else 'Oflokkad'
  end LCR_EBA_CAT,
  case when cur_LCR = 'ISK' then marketvalueISK else 0 end Exposure_ISK,
  case when cur_LCR = 'EUR' then marketvalueISK else 0 end Exposure_EUR,
  case when cur_LCR = 'USD' then marketvalueISK else 0 end Exposure_USD,
  case when cur_LCR = 'ADRIR' then marketvalueISK else 0 end Exposure_ANNAD
  from LCR.LCR_FMEFOREIGNPAPERS
  where execdate = inLoadDate
  ) 
  group by the_Date,  LCR_SI_CAT, LCR_EBA_CAT
  --innlend r?kiskuldabr?f og ?nnur repoh?f --isgogn

  UNION ALL

  select 
    the_date, LCR_SI_CAT, LCR_EBA_CAT, 
    round(sum(Exposure_ISK),0) ISK_AMT, 
    round(sum(Exposure_EUR),0) EUR_AMT, 
    round(sum(Exposure_USD),0) USD_AMT, 
    round(sum(Exposure_ANNAD),0) ANNAD_AMT
  from (
  select execdate the_date, currency,
  case when Bond like ('RIKS%') then 'HQLA 3.3' 
  when Bond like ('RIK%') then 'HQLA 3.2' 
  when Bond like ('HFF%') then 'HQLA 3.4'
  when Bond like ('RVK091%') then 'HQLA 3.6'
  when Bond like ('LSS150224%') then 'HQLA 3.6'
  else 'Oflokkad'
  end LCR_SI_CAT, 
  case when Bond like ('RIK%') then '070' 
  when Bond like ('HFF%') then '090'
  when Bond like ('RVK091%') then '080'
  when Bond like ('LSS150224%') then '090'
  else 'Oflokkad'
  end LCR_EBA_CAT,
  case when currency = 'ISK' then market_value else 0 end Exposure_ISK,
  case when currency = 'EUR' then market_value else 0 end Exposure_EUR,
  case when currency = 'USD' then market_value else 0 end Exposure_USD,
  case when currency not in ('ISK','EUR','USD') then market_value else 0 end Exposure_ANNAD
  from LCR.LCR_REPO_PAPERS
  where execdate = inLoadDate
  ) 
  group by the_Date,  LCR_SI_CAT, LCR_EBA_CAT
  ;

  rowsInserted := SQL%ROWCOUNT;
  LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,rowsInserted,NULL,rowsDeleted,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'END',logMessage,NULL);
  commit;

  exception when others then
    begin
      LCR.UTIL_RUN_LOGGER.LOG(wmodule,gprogram,NULL,NULL,rowsDeleted,LCR.UTIL_RUN_LOGGER.TIME_DIFF(timestampStart),'ERROR',logMessage || ' - ' || DBMS_UTILITY.format_error_backtrace ,NULL);
      rollback;
      raise;
    end;

end;


end;
/