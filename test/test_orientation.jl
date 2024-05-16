@testset "123 model" begin
    using XLSX, MPSGE_MP.JuMP.Containers
    import JuMP

    goods = Symbol.(:g,1:10)
    regions = Symbol.(:r,1:10)

    x = DenseAxisArray([0.171747, 0.843267, 0.550375, 0.301138, 0.292212, 0.224053, 0.349831, 0.856270, 0.067114, 0.500211], regions)
    y = DenseAxisArray([0.998118, 0.578733, 0.991133, 0.762250, 0.130692, 0.639719, 0.159518, 0.250081, 0.668929, 0.435356], regions)

    ω = DenseAxisArray([0.35970026600000005 0.35144136800000003 0.13149159000000002 0.150101788 0.58911365 0.8308928120000001 0.23081573800000002 0.66573446 0.7758576060000001 0.30365847700000004;
                    0.110492291 0.502384866 0.160172762 0.872462311 0.26511454500000003 0.285814322 0.593955922 0.722719071 0.6282486770000001 0.46379786500000003;
                    0.41330699400000004 0.117695357 0.31421226700000005 0.046551514 0.33855027200000004 0.182099593 0.645727127 0.560745547 0.7699617200000001 0.29780586400000003;
                    0.661106261 0.755821674 0.6274474990000001 0.283864198 0.086424624 0.102514669 0.6412511510000001 0.5453094980000001 0.031524852 0.792360642;
                    0.072766998 0.175661049 0.5256326130000001 0.750207669 0.17812371400000002 0.034140986000000005 0.5851311730000001 0.6212299840000001 0.38936190000000004 0.35871415300000004;
                    0.243034617 0.24642153900000002 0.130502803 0.93344972 0.37993790600000005 0.783400461 0.300034258 0.125483222 0.7488741050000001 0.06923246300000001;
                    0.202015557 0.005065858 0.269613052 0.49985147500000005 0.15128586900000002 0.174169455 0.330637734 0.316906054 0.322086955 0.963976641;
                    0.9936022050000001 0.36990305500000004 0.372888567 0.77197833 0.396684142 0.913096325 0.11957773000000001 0.735478889 0.055418475 0.576299805;
                    0.051407110000000006 0.006008368 0.401227683 0.5198811870000001 0.628877255 0.22574988 0.396121408 0.27600613100000004 0.15237260800000002 0.9363228360000001;
                    0.42266059 0.13466312900000002 0.38605561400000005 0.37463274700000004 0.26848104 0.948370515 0.18894032500000002 0.297509548 0.074552766 0.40134625700000004
                    ], 
        goods, regions
        )


    weight = DenseAxisArray([0.101689, 0.383890, 0.324094, 0.192134, 0.112368, 0.596558, 0.511449, 0.045066, 0.783102, 0.945749],goods)


    distance = DenseAxisArray(zeros(length(regions),length(regions)) , regions,regions)
    for r∈regions,s∈regions
        distance[r,s] = sqrt( (x[r]-x[s])^2 + (y[r]-y[s])^2)
    end
    
    
    L = 1
    
    phi = DenseAxisArray(zeros(length(goods),length(regions),length(regions)),goods,regions,regions)
    for g∈goods,r∈regions,rr∈regions
        phi[g,r,rr] = distance[r,rr]/sqrt(2)*weight[g]
    end
    
    
    
    transport = DenseAxisArray(zeros(length(regions),length(regions),length(regions)), regions,regions,regions)
    for (h_i,home)∈enumerate(regions),(r_i,r)∈enumerate(regions)
        if r_i<h_i
            transport[home,r,home] = 1
        elseif r_i>h_i
            transport[home,home,r] = 1
        end
    end
    

    mules_mpsge = MPSGEModel()

    @sectors(mules_mpsge, begin
        exports[goods,regions,regions]
        porters[regions,regions,regions]
    end)

    @commodities(mules_mpsge, begin
        P[goods,regions]
        PL[regions]
        PT[regions,regions]
    end)

    @consumer(mules_mpsge, RA[regions])

    for g∈goods,r∈regions,rr∈regions
        if r!=rr
            @production(mules_mpsge, exports[g,r,rr], [s=0,t=0], begin
                @output(P[g,rr], 1, t)
                @input(P[g,r], 1, s)
                @input(PT[r,rr], phi[g,r,rr], s)
            end)
        end
    end


    for h∈regions,r∈regions,rr∈regions
        if transport[h,r,rr]==1
            @production(mules_mpsge, porters[h,r,rr], [s=0,t=0], begin
                @output(PT[r,rr], 1, t)
                @output(PT[rr,r], 1, t)
                @input(PL[h], 1, s)
            end)
        end
    end


    for r∈regions
        @demand(mules_mpsge, RA[r], begin
            [@final_demand(P[g,r], 1) for g∈goods]...
            @final_demand(PL[r], 1)
        end,begin
            @endowment(PL[r], 1)
            [@endowment(P[g,r], ω[g,r]) for g∈goods]...
        end)
        
    end

    fix(RA[:r4], 1+sum(ω[g,:r4] for g∈goods))

    #set_silent(mules_mpsge)
    solve!(mules_mpsge)

    df_mpsge = generate_report(mules_mpsge);

    @test JuMP.is_solved_and_feasible(jump_model(mules_mpsge))


end