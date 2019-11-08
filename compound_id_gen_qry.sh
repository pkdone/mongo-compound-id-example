#!/bin/bash
echo "Running data ingestion + query Mongo Shell script to demonstrate compound _id key"

mongo --quiet --eval "
    const MINS_MAX = 84;
    const PTN_MAX = 120;
    const SEQ_MAX = 10;
    const STARTTIME = 1573211768000;  // Epoch for Friday, 8 November 2019 11:16:08.000 UTC
    db = db.getSiblingDB('testdb');
    db.records.drop()
    let min;
    print('Generating ' + (MINS_MAX*PTN_MAX*SEQ_MAX) + ' records');

    for (min = 0; min < MINS_MAX; min++) {    
        let now = STARTTIME + (min * 1000 * 60);
        let ptn;

        for (ptn = 0; ptn < PTN_MAX; ptn++) {
            let seq;

            for (seq = 0; seq < SEQ_MAX; seq++) {
                db.records.insertOne({
                    '_id': {'ptn': ptn, 'ts': now, 'seq': seq}, 
                    'value': Math.random()
                });
            }   
        }
    }


    print('Finished inserting records, now moving on to query phase...')
    let query_ptn = Math.floor(0.5 * PTN_MAX);  // query middle partition
    let query_ts = STARTTIME + (Math.floor(0.5 * MINS_MAX) * 1000 * 60);  // query middle date


    //
    // Equality query test (find a single record)
    //
    print('Equality query for single record, leveraging index, for key: ptn=' + query_ptn + ', ts=' + query_ts + ', seq=0');

    print(db.records.find({
        '_id': {'ptn': query_ptn, 'ts': query_ts, 'seq': 0}
    }).forEach(printjson));

    printjson(db.records.find({
        '_id': {'ptn': query_ptn, 'ts': query_ts, 'seq': 0}
    }).explain('executionStats'));


    //
    // Range query test (find a set of records)
    //
    print('Range query for set of records, leveraging index, for range: ptn=' + query_ptn + ', ts=' + query_ts);

    print(db.records.find({
        '_id': {
            '\$gte': {'ptn': query_ptn, 'ts': query_ts, 'seq': MinKey},
            '\$lte': {'ptn': query_ptn, 'ts': query_ts, 'seq': MaxKey}
        }
    }).limit(SEQ_MAX + 2).forEach(printjson));

    printjson(db.records.find({
        '_id': {
            '\$gte': {'ptn': query_ptn, 'ts': query_ts, 'seq': MinKey},
            '\$lte': {'ptn': query_ptn, 'ts': query_ts, 'seq': MaxKey}
        }
    }).explain('executionStats'));
"
echo "Finished processing"


