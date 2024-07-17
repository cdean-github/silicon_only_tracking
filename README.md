# Silicon only tracking

## Compilation

You should compile this version of ```trackreco```. Joe commited it on July 10th so if sourcing the ```new``` build of sPHENIX causese compilation errors then you can use an ana build which should be compatible

| Ana build | Date made |
|-----------|-----------|
| ana.426   | July  6th |
| ana.427   | July 13th |

I have some handy bash scripts for building
```bash
alias buildThisProject="mkdir build && cd build && ../autogen.sh --prefix=$MYINSTALL && make && make install && cd ../"
```
Navigate first to `metadata` then `metadatacontainer` and execute the above command. Remember to have your work environment set up to allow local software builds with something like what I keep in my `.bash_profile`
```bash
source /opt/sphenix/core/bin/sphenix_setup.sh -n new
export SPHENIX=/sphenix/u/cdean/sPHENIX
export MYINSTALL=$SPHENIX/install
export LD_LIBRARY_PATH=$MYINSTALL/lib:$LD_LIBRARY_PATH
export ROOT_INCLUDE_PATH=$MYINSTALL/include:$ROOT_INCLUDE_PATH
source /opt/sphenix/core/bin/setup_local.sh $MYINSTALL
```

## Running silicon-only tracking

If the folder ```hf_generator``` is the code I used to study silicon-only D0 reconstruction. The important part to get the silicon-only tracking running is copied below. Effectively you should turn off the TPC (and TPOT) clustering, then you never call the TPC seeding. This is what the example code does. You:

1. Simulate hits in the silicon
2. Digitize the hits
3. Cluster the silicon detectors
4. Create seeds (tracklets) from the INTT and MVTX
5. Merge those seeds into a full silicon seed
6. Run the ACTS tracking through the modified algorithms in this repo using just the silicon seeds

```c++
  //Simulation setup

  Enable::MBDFAKE = true;
  Enable::PIPE = true;
  Enable::PIPE_ABSORBER = true;
  Enable::MVTX = true;
  Enable::INTT = true;
  Enable::TPC = true;
  Enable::MICROMEGAS = true;

  //Tracking setup

  Enable::CDB = true;
  rc->set_StringFlag("CDB_GLOBALTAG",CDB::global_tag);
  rc->set_uint64Flag("TIMESTAMP",CDB::timestamp);

  MagnetInit();
  MagnetFieldInit();

  G4Init();
  G4Setup();

  Mbd_Reco();
  Mvtx_Cells();
  Intt_Cells();
  TPC_Cells();
  Micromegas_Cells();

  TrackingInit();

  Mvtx_Clustering();
  Intt_Clustering();
  //TPC_Clustering();
  //Micromegas_Clustering();

  auto silicon_Seeding = new PHActsSiliconSeeding;
  //silicon_Seeding->set_track_map_name("SvtxTrackSeedContainer");
  silicon_Seeding->Verbosity(0);
  silicon_Seeding->searchInIntt();
  silicon_Seeding->setinttRPhiSearchWindow(0.4);
  silicon_Seeding->setinttZSearchWindow(1.6);
  silicon_Seeding->seedAnalysis(false);
  se->registerSubsystem(silicon_Seeding);

  auto merger = new PHSiliconSeedMerger;
  //merger->trackMapName("SvtxTrackSeedContainer");
  merger->Verbosity(0);
  se->registerSubsystem(merger);

  auto actsFit = new PHActsTrkFitter;
  actsFit->Verbosity(0);
  actsFit->commissioning(G4TRACKING::use_alignment);
  // in calibration mode, fit only Silicons and Micromegas hits
  actsFit->fitSiliconMMs(G4TRACKING::SC_CALIBMODE);
  actsFit->setUseMicromegas(G4TRACKING::SC_USE_MICROMEGAS);
  actsFit->set_pp_mode(TRACKING::pp_mode);
  actsFit->set_use_clustermover(true);  // default is true for now
  actsFit->useActsEvaluator(false);
  actsFit->useOutlierFinder(false);
  actsFit->setFieldMap(G4MAGNET::magfield_tracking);
  se->registerSubsystem(actsFit);

  PHSimpleVertexFinder *finder = new PHSimpleVertexFinder;
  finder->Verbosity(0);
  finder->setDcaCut(0.1);
  finder->setTrackPtCut(0.);
  finder->setBeamLineCut(1);
  finder->setTrackQualityCut(20);
  finder->setNmvtxRequired(3);
  finder->setOutlierPairCut(0.1);
  se->registerSubsystem(finder);

  //Tracking_Reco();
  Global_Reco();
``` 
