% ============================================================
%  laptop_advisor.pl (Complete Version)
%  Laptop purchase recommendation expert system
%  Includes: Fuzzy Logic + Heuristics (CPU suffix) + Brand CF
%            + Meta-rules (impossible budget) + Backward Chaining
%            + Ranking system and Top-K results.
% ============================================================

:- encoding(utf8).
:- discontiguous soft_property_internal/2.
:- consult('laptop_database.pl').

% ============================================================
% 1) GENERAL UTILITIES
% ============================================================

contains_ignore_case(Text, Key) :-
    downcase_atom(Text, T),
    downcase_atom(Key, K),
    sub_string(T, _, _, _, K).



clamp01(X, 0.0) :- X < 0, !.
clamp01(X, 1.0) :- X > 1, !.
clamp01(X, X).

remove_item(_, [], []).
remove_item(X, [X|T], R) :- !, remove_item(X, T, R).
remove_item(X, [H|T], [H|R]) :- remove_item(X, T, R).

normalize_requirement_list([], []) :- !.
normalize_requirement_list([H|T], [H|T]) :- !.
normalize_requirement_list(Atom, [Atom]).

normalize_need(office, office).
normalize_need(programming, programming).
normalize_need(ios_development, ios_development).
normalize_need(graphics, graphics).
normalize_need(gaming, gaming).
normalize_need(ai_data_science, ai_data_science).
normalize_need(office, office).
normalize_need(programming, programming).
normalize_need(ios_development, ios_development).
normalize_need(graphics, graphics).

normalize_requirement(lightweight, lightweight).
normalize_requirement(long_battery_life, long_battery_life).
normalize_requirement(budget_friendly, budget_friendly).
normalize_requirement(mid_range, mid_range).
normalize_requirement(large_display, large_display).
normalize_requirement(discrete_gpu, discrete_gpu).
normalize_requirement(integrated_gpu, integrated_gpu).
normalize_requirement(preferred_brand(Hang), preferred_brand(Hang)).
normalize_requirement(thich_thuong_hieu(Hang), preferred_brand(Hang)).
normalize_requirement(performance_priority, performance_priority).
normalize_requirement(very_cheap, very_cheap).
normalize_requirement(budget_friendly, budget_friendly).
normalize_requirement(mid_range, mid_range).
normalize_requirement(high_end, high_end).
normalize_requirement(lightweight, lightweight).
normalize_requirement(heavy, heavy).
normalize_requirement(small_display, small_display).
normalize_requirement(large_display, large_display).
normalize_requirement(medium_display, medium_display).
normalize_requirement(long_battery_life, long_battery_life).
normalize_requirement(discrete_gpu, discrete_gpu).
normalize_requirement(integrated_gpu, integrated_gpu).

normalize_requirements([], []).
normalize_requirements([H|T], [NH|NT]) :-
    normalize_requirement(H, NH),
    normalize_requirements(T, NT).
normalize_requirements(Atom, [Normalized]) :-
    Atom \= [],
    Atom \= [_|_],
    normalize_requirement(Atom, Normalized).

soft_property(Name, Property) :-
    soft_property_internal(Name, Property).

soft_property_internal(Name, very_cheap) :- laptop(Name, _, Gia, _, _, _, _, _, _, _), very_cheap(Gia).
soft_property_internal(Name, budget_friendly) :- laptop(Name, _, Gia, _, _, _, _, _, _, _), budget_friendly(Gia).
soft_property_internal(Name, mid_range) :- laptop(Name, _, Gia, _, _, _, _, _, _, _), mid_range(Gia).
soft_property_internal(Name, high_end) :- laptop(Name, _, Gia, _, _, _, _, _, _, _), high_end(Gia).

soft_property_internal(Name, lightweight) :- laptop(Name, _, _, _, _, _, _, _, _, KL), lightweight(KL).
soft_property_internal(Name, heavy) :- laptop(Name, _, _, _, _, _, _, _, _, KL), heavy(KL).

soft_property_internal(Name, small_display) :- laptop(Name, _, _, _, _, _, _, Man, _, _), small_display(Man).
soft_property_internal(Name, large_display) :- laptop(Name, _, _, _, _, _, _, Man, _, _), large_display(Man).

soft_property_internal(Name, long_battery_life) :- laptop(Name, _, _, _, _, _, _, _, Pin, _), long_battery_life(Pin).

minimum_requirements(Workload, RequiredRam, RequiredSsd) :-
    minimum_requirements_internal(Workload, RequiredRam, RequiredSsd).

matches_workload(Workload, CPU, GPU, RAM, SSD) :-
    matches_workload_internal(Workload, CPU, GPU, RAM, SSD).

resolve_conflicts(Workload, Budget, Requirements, EffectiveRequirements, Warning) :-
    resolve_conflicts_internal(Workload, Budget, Requirements, EffectiveRequirements, Warning).

total_cf(Name, Workload, Budget, RequiredRam, RequiredSsd, EffectiveRequirements, TotalCF) :-
    total_cf_internal(Name, Workload, Budget, RequiredRam, RequiredSsd, EffectiveRequirements, TotalCF).

% ============================================================
% 2) FUZZY LOGIC - Soft rules (numeric -> qualitative)
% ============================================================

% ---- Price fuzziness ----
very_cheap(Gia) :- Gia =< 15000000.
budget_friendly(Gia)     :- Gia > 15000000, Gia =< 25000000.
mid_range(Gia)  :- Gia > 25000000, Gia =< 40000000.
high_end(Gia)    :- Gia > 40000000.

% ---- Weight fuzziness ----
very_light(KL)  :- KL =< 1.2.
lightweight(KL) :- KL > 1.2, KL =< 1.5.
balanced(KL) :- KL > 1.5, KL =< 2.0.
heavy(KL)     :- KL > 2.0.

% ---- Display fuzziness ----
small_display(Man) :- Man < 14.0.
medium_display(Man) :- Man >= 14.0, Man =< 15.6.
large_display(Man)  :- Man > 15.6.

% ---- Battery fuzziness ----
battery_weak(Pin)        :- Pin < 50.
battery_mid(Pin) :- Pin >= 50, Pin < 70.
long_battery_life(Pin)       :- Pin >= 70.

% ---- Soft labels for each laptop ----
soft_property_internal(Ten, very_cheap) :- laptop(Ten, _, Gia, _, _, _, _, _, _, _), very_cheap(Gia).
soft_property_internal(Ten, budget_friendly)     :- laptop(Ten, _, Gia, _, _, _, _, _, _, _), budget_friendly(Gia).
soft_property_internal(Ten, mid_range)  :- laptop(Ten, _, Gia, _, _, _, _, _, _, _), mid_range(Gia).
soft_property_internal(Ten, high_end)    :- laptop(Ten, _, Gia, _, _, _, _, _, _, _), high_end(Gia).

soft_property_internal(Ten, lightweight)   :- laptop(Ten, _, _, _, _, _, _, _, _, KL), lightweight(KL).
soft_property_internal(Ten, heavy)       :- laptop(Ten, _, _, _, _, _, _, _, _, KL), heavy(KL).

soft_property_internal(Ten, small_display)    :- laptop(Ten, _, _, _, _, _, _, Man, _, _), small_display(Man).
soft_property_internal(Ten, large_display)     :- laptop(Ten, _, _, _, _, _, _, Man, _, _), large_display(Man).

soft_property_internal(Ten, long_battery_life)   :- laptop(Ten, _, _, _, _, _, _, _, Pin, _), long_battery_life(Pin).

% ============================================================
% 3) HEURISTICS - Experience-based rules by workload
% ============================================================

% ---- GPU detection ----
discrete_gpu(GPU) :- contains_ignore_case(GPU, 'rtx').
discrete_gpu(GPU) :- contains_ignore_case(GPU, 'gtx').
discrete_gpu(GPU) :- contains_ignore_case(GPU, 'geforce mx').
discrete_gpu(GPU) :- contains_ignore_case(GPU, 'radeon rx').
discrete_gpu(GPU) :- contains_ignore_case(GPU, 'radeon 8060s').

integrated_gpu(GPU) :- contains_ignore_case(GPU, 'intel graphics').
integrated_gpu(GPU) :- contains_ignore_case(GPU, 'intel iris').
integrated_gpu(GPU) :- contains_ignore_case(GPU, 'intel uhd').
integrated_gpu(GPU) :- contains_ignore_case(GPU, 'apple').
integrated_gpu(GPU) :- contains_ignore_case(GPU, 'amd radeon graphics').
integrated_gpu(GPU) :- contains_ignore_case(GPU, 'qualcomm').

% ---- CPU suffix detection ----
cpu_high_performance(CPU) :- contains_ignore_case(CPU, 'h').
cpu_high_performance(CPU) :- contains_ignore_case(CPU, 'hx').
cpu_high_performance(CPU) :- contains_ignore_case(CPU, 'pro').
cpu_high_performance(CPU) :- contains_ignore_case(CPU, 'max').
% ---- Add newer AMD chips (without H suffix) ----
cpu_high_performance(CPU) :- contains_ignore_case(CPU, 'ryzen ai').
cpu_high_performance(CPU) :- contains_ignore_case(CPU, 'ryzen 7 260').
cpu_high_performance(CPU) :- contains_ignore_case(CPU, 'ryzen 7 250').

% ---- Basic CPU strength classification ----
cpu_basic(CPU) :- contains_ignore_case(CPU, 'i3').
cpu_basic(CPU) :- contains_ignore_case(CPU, 'core 3').

cpu_mid_range(CPU) :- contains_ignore_case(CPU, 'i5').
cpu_mid_range(CPU) :- contains_ignore_case(CPU, 'ryzen 5').
cpu_mid_range(CPU) :- contains_ignore_case(CPU, 'ultra 5').

cpu_strong(CPU) :- contains_ignore_case(CPU, 'i7').
cpu_strong(CPU) :- contains_ignore_case(CPU, 'i9').
cpu_strong(CPU) :- contains_ignore_case(CPU, 'ultra 7').
cpu_strong(CPU) :- contains_ignore_case(CPU, 'ryzen 7').
cpu_strong(CPU) :- contains_ignore_case(CPU, 'ryzen 9').
cpu_strong(CPU) :- contains_ignore_case(CPU, 'apple m').
cpu_strong(CPU) :- contains_ignore_case(CPU, 'snapdragon x').

cpu_adequate(CPU) :- cpu_basic(CPU) ; cpu_mid_range(CPU) ; cpu_strong(CPU).

% ---- Strong GPUs for gaming ----
gpu_gaming_strong(GPU) :- contains_ignore_case(GPU, 'rtx 3070').
gpu_gaming_strong(GPU) :- contains_ignore_case(GPU, 'rtx 3080').
gpu_gaming_strong(GPU) :- contains_ignore_case(GPU, 'rtx 4070').
gpu_gaming_strong(GPU) :- contains_ignore_case(GPU, 'rtx 4080').
gpu_gaming_strong(GPU) :- contains_ignore_case(GPU, 'rtx 4090').

% ---- High-end discrete GPUs ----
gpu_discrete_high_end(GPU) :- contains_ignore_case(GPU, 'rtx 4050').
gpu_discrete_high_end(GPU) :- contains_ignore_case(GPU, 'rtx 4060').
gpu_discrete_high_end(GPU) :- contains_ignore_case(GPU, 'rtx 3060').
gpu_discrete_high_end(GPU) :- contains_ignore_case(GPU, 'radeon rx 6700').
gpu_discrete_high_end(GPU) :- contains_ignore_case(GPU, 'radeon 6600m').

% ---- Mid-range discrete GPUs ----
gpu_discrete_mid_range(GPU) :- contains_ignore_case(GPU, 'geforce mx 550').
gpu_discrete_mid_range(GPU) :- contains_ignore_case(GPU, 'gtx 1650').
gpu_discrete_mid_range(GPU) :- contains_ignore_case(GPU, 'gtx 1660').

% ---- GPU accelerators for AI / Machine Learning ----
gpu_ai_accelerator(GPU) :- contains_ignore_case(GPU, 'rtx 4090').
gpu_ai_accelerator(GPU) :- contains_ignore_case(GPU, 'rtx 4080').
gpu_ai_accelerator(GPU) :- contains_ignore_case(GPU, 'rtx 4070').
gpu_ai_accelerator(GPU) :- contains_ignore_case(GPU, 'rtx 3080').
gpu_ai_accelerator(GPU) :- contains_ignore_case(GPU, 'rtx 3070').
gpu_ai_accelerator(GPU) :- contains_ignore_case(GPU, 'rtx 4060').


% ---- Minimum configuration by workload ----
minimum_requirements_internal(office, 8, 256).
minimum_requirements_internal(programming, 16, 512).
minimum_requirements_internal(ios_development, 16, 512).
minimum_requirements_internal(graphics, 16, 512).
minimum_requirements_internal(gaming, 16, 512).
minimum_requirements_internal(ai_data_science, 16, 512).

% ---- Workload filters ----
matches_workload_internal(office, CPU, _GPU, RAM, SSD) :-
    RAM >= 8, SSD >= 256, cpu_adequate(CPU).

matches_workload_internal(programming, CPU, _GPU, RAM, SSD) :-
    RAM >= 16, SSD >= 512, (cpu_mid_range(CPU) ; cpu_strong(CPU)).

matches_workload_internal(ios_development, CPU, _GPU, RAM, SSD) :-
    RAM >= 16, SSD >= 512, contains_ignore_case(CPU, 'apple').

matches_workload_internal(graphics, CPU, GPU, RAM, SSD) :-
    RAM >= 16, SSD >= 512,
    ( (discrete_gpu(GPU), cpu_high_performance(CPU)) ; contains_ignore_case(CPU, 'apple') ).

matches_workload_internal(gaming, CPU, GPU, RAM, SSD) :-
    RAM >= 16, SSD >= 512, discrete_gpu(GPU), 
    (gpu_gaming_strong(GPU) ; gpu_discrete_high_end(GPU)),
    cpu_high_performance(CPU).


% ---- Requirements for AI / Data Science ----
matches_workload_internal(ai_data_science, CPU, GPU, RAM, SSD) :-
    RAM >= 32, SSD >= 512,
    ( gpu_ai_accelerator(GPU) ; cpu_strong(CPU) ).


% ============================================================
% 4) META-RULES - Conflict resolution
% ============================================================

resolve_conflicts_internal(Workload, Budget, Requirements, EffectiveRequirements, Warning) :-
    normalize_need(Workload, WorkloadN),
    normalize_requirements(Requirements, Y0),
    handle_conflict_budget(WorkloadN, Budget, C0),
    handle_conflict_gaming_lightweight(WorkloadN, Y0, Y1, C1),
    handle_conflict_graphics_budget(WorkloadN, Y1, Y2, C2),
    handle_conflict_gaming_battery(WorkloadN, Y2, Y3, C3),
    handle_conflict_large_display_lightweight(WorkloadN, Y3, Y4, C4),
    handle_conflict_performance_integrated_gpu(WorkloadN, Y4, EffectiveRequirements, C5),
    merge_warnings([C0, C1, C2, C3, C4, C5], Warning).

handle_conflict_budget(Workload, Budget, Warning) :-
    ( (Workload == gaming ; Workload == graphics), Budget > 0, Budget < 15000000 ->
        Warning = 'Warning: budgets below VND 15 million make it hard to find a new laptop that fits gaming/graphics well.'
    ; Workload == ios_development, Budget > 0, Budget < 18000000 ->
        Warning = 'Warning: MacBooks that work well for iOS development often cost more than VND 18 million, so this budget may be too low.'
    ; Warning = none ).

handle_conflict_gaming_lightweight(Workload, Yin, Yout, Warning) :-
    ( Workload == gaming, member(lightweight, Yin) ->
        remove_item(lightweight, Yin, Ytmp), Yout = [performance_priority|Ytmp],
        Warning = 'Conflict: gaming + lightweight. The system drops lightweight and prioritizes performance.'
    ; Yout = Yin, Warning = none ).

handle_conflict_graphics_budget(Workload, Yin, Yout, Warning) :-
    ( Workload == graphics, member(budget_friendly, Yin) ->
        remove_item(budget_friendly, Yin, Ytmp), Yout = [mid_range|Ytmp],
        Warning = 'Conflict: graphics + budget-friendly. The system upgrades to mid-range to preserve GPU performance.'
    ; Yout = Yin, Warning = none ).

handle_conflict_gaming_battery(Workload, Yin, Yout, Warning) :-
    ( Workload == gaming, member(long_battery_life, Yin) ->
        Yout = Yin, Warning = 'Warning: gaming + long battery life is difficult to optimize at the same time.'
    ; Yout = Yin, Warning = none ).

handle_conflict_large_display_lightweight(_Workload, Yin, Yout, Warning) :-
    ( member(large_display, Yin), member(lightweight, Yin) ->
        remove_item(large_display, Yin, Ytmp), Yout = [medium_display|Ytmp],
        Warning = 'Conflict: large display + lightweight. The system downgrades the display size to medium.'
    ; Yout = Yin, Warning = none ).

handle_conflict_performance_integrated_gpu(Workload, Yin, Yout, Warning) :-
    ( member(integrated_gpu, Yin), (Workload == gaming ; Workload == graphics) ->
        remove_item(integrated_gpu, Yin, Ytmp), Yout = [discrete_gpu|Ytmp],
        Warning = 'Conflict: high-performance workloads should not use integrated GPU. The system switches to discrete GPU.'
    ; Yout = Yin, Warning = none ).

merge_warnings([], []).
merge_warnings([none|T], R) :- !, merge_warnings(T, R).
merge_warnings([H|T], [H|R]) :- merge_warnings(T, R).


% ============================================================
% 5) Check extra requirements after meta-rules
% ============================================================

meets_extra_requirements(_Name, []).
meets_extra_requirements(Name, [H|T]) :- normalize_requirement(H, N), meets_one_requirement(Name, N), meets_extra_requirements(Name, T).
meets_extra_requirements(Name, Atom) :- Atom \= [], Atom \= [_|_], normalize_requirement(Atom, N), meets_one_requirement(Name, N).

thoa_yeu_cau_them(Name, Requirements) :-
    meets_extra_requirements(Name, Requirements).

meets_one_requirement(_Name, performance_priority).
meets_one_requirement(_Name, preferred_brand(_)).

meets_one_requirement(Name, budget_friendly) :- soft_property(Name, budget_friendly).
meets_one_requirement(Name, mid_range) :- soft_property(Name, mid_range).
meets_one_requirement(Name, high_end) :- soft_property(Name, high_end).
meets_one_requirement(Name, lightweight) :- soft_property(Name, lightweight).
meets_one_requirement(Name, heavy) :- soft_property(Name, heavy).
meets_one_requirement(Name, small_display) :- soft_property(Name, small_display).
meets_one_requirement(Name, large_display) :- soft_property(Name, large_display).
meets_one_requirement(Name, medium_display) :- laptop(Name, _, _, _, _, _, _, Screen, _, _), medium_display(Screen).
meets_one_requirement(Name, long_battery_life) :- soft_property(Name, long_battery_life).

meets_one_requirement(Name, brand(Brand)) :- laptop(Name, Brand, _, _, _, _, _, _, _, _).
meets_one_requirement(Name, preferred_brand(Brand)) :- laptop(Name, Brand, _, _, _, _, _, _, _, _).
meets_one_requirement(Name, discrete_gpu) :- laptop(Name, _, _, _, GPU, _, _, _, _, _), discrete_gpu(GPU).
meets_one_requirement(Name, integrated_gpu) :- laptop(Name, _, _, _, GPU, _, _, _, _, _), integrated_gpu(GPU).
meets_one_requirement(Name, very_cheap) :- soft_property(Name, very_cheap).
meets_one_requirement(Name, budget_friendly) :- soft_property(Name, budget_friendly).
meets_one_requirement(Name, mid_range) :- soft_property(Name, mid_range).
meets_one_requirement(Name, high_end) :- soft_property(Name, high_end).
meets_one_requirement(Name, lightweight) :- soft_property(Name, lightweight).
meets_one_requirement(Name, heavy) :- soft_property(Name, heavy).
meets_one_requirement(Name, small_display) :- soft_property(Name, small_display).
meets_one_requirement(Name, large_display) :- soft_property(Name, large_display).
meets_one_requirement(Name, medium_display) :- soft_property(Name, medium_display).
meets_one_requirement(Name, long_battery_life) :- soft_property(Name, long_battery_life).
meets_one_requirement(Name, discrete_gpu) :- laptop(Name, _, _, _, GPU, _, _, _, _, _), discrete_gpu(GPU).
meets_one_requirement(Name, integrated_gpu) :- laptop(Name, _, _, _, GPU, _, _, _, _, _), integrated_gpu(GPU).

meets_one_requirement(_, performance_priority).


% ============================================================
% 6) CERTAINTY FACTOR (CF)
% ============================================================

% ---- Price CF ----
tinh_diem_cf(Price, Budget, PriceCF) :-
    ( Price =< Budget * 0.7 -> PriceCF = 1.0
    ; Price =< Budget * 0.85 -> PriceCF = 0.9
    ; Price =< Budget * 1.1 -> PriceCF = 0.8
    ; Price =< Budget * 1.3 -> PriceCF = 0.5
    ; PriceCF = 0.2 ).

% ---- RAM CF ----
cf_thuong_ram(Ram, RequiredRam, RamCF) :-
    ( Ram >= RequiredRam * 2 -> RamCF = 1.0
    ; Ram >= RequiredRam * 1.5 -> RamCF = 0.9
    ; Ram >= RequiredRam -> RamCF = 0.85
    ; RamCF = 0.5 ).

% ---- SSD CF ----
cf_thuong_ssd(Ssd, RequiredSsd, SsdCF) :-
    ( Ssd >= RequiredSsd * 2 -> SsdCF = 1.0
    ; Ssd >= RequiredSsd * 1.5 -> SsdCF = 0.9
    ; Ssd >= RequiredSsd -> SsdCF = 0.85
    ; SsdCF = 0.5 ).

brand_bonus(Name, Requirements, Bonus) :-
    ( member(preferred_brand(FavBrand), Requirements), laptop(Name, FavBrand, _, _, _, _, _, _, _, _) ->
        Bonus = 0.15
    ; Bonus = 0.0 ).

total_cf_internal(Name, Workload, Budget, RequiredRam, RequiredSsd, EffectiveRequirements, TotalCF) :-
    laptop(Name, _, Price, _CPU, GPU, Ram, Ssd, _Screen, Battery, Weight),
    calculate_price_cf(Price, Budget, PriceCF),
    calculate_ram_cf(Ram, RequiredRam, RamCF),
    calculate_ssd_cf(Ssd, RequiredSsd, SsdCF),
    calculate_gpu_cf(GPU, Workload, GpuCF),
    calculate_battery_cf(Battery, Workload, BatteryCF),
    calculate_weight_cf(Weight, Workload, WeightCF),
    brand_bonus(Name, EffectiveRequirements, BrandBonus),
    
    Raw is 0.35*PriceCF + 0.15*RamCF + 0.10*SsdCF + 0.20*GpuCF + 0.10*BatteryCF + 0.10*WeightCF + BrandBonus,
    clamp01(Raw, TotalCF).

price_cf(Price, Budget, PriceCF) :- calculate_price_cf(Price, Budget, PriceCF).
ram_bonus_cf(Ram, RequiredRam, RamCF) :- calculate_ram_cf(Ram, RequiredRam, RamCF).
ssd_bonus_cf(Ssd, RequiredSsd, SsdCF) :- calculate_ssd_cf(Ssd, RequiredSsd, SsdCF).
gpu_workload_cf(GPU, Workload, GpuCF) :- calculate_gpu_cf(GPU, Workload, GpuCF).
battery_workload_cf(Battery, Workload, BatteryCF) :- calculate_battery_cf(Battery, Workload, BatteryCF).
weight_workload_cf(Weight, Workload, WeightCF) :- calculate_weight_cf(Weight, Workload, WeightCF).

calculate_price_cf(Price, Budget, PriceCF) :- tinh_diem_cf(Price, Budget, PriceCF).
calculate_ram_cf(Ram, RequiredRam, RamCF) :- cf_thuong_ram(Ram, RequiredRam, RamCF).
calculate_ssd_cf(Ssd, RequiredSsd, SsdCF) :- cf_thuong_ssd(Ssd, RequiredSsd, SsdCF).

calculate_gpu_cf(GPU, Workload, GpuCF) :-
    ( Workload == ai_data_science -> (
          ( gpu_ai_accelerator(GPU) -> GpuCF = 1.0
          ; gpu_discrete_high_end(GPU)       -> GpuCF = 0.9
          ; gpu_discrete_mid_range(GPU)    -> GpuCF = 0.6
          ; integrated_gpu(GPU)           -> GpuCF = 0.3
          ; GpuCF = 0.5 )
      )
    ; Workload == gaming -> (gpu_gaming_strong(GPU) -> GpuCF=1.0 ; gpu_discrete_high_end(GPU) -> GpuCF=0.75 ; gpu_discrete_mid_range(GPU) -> GpuCF=0.4 ; discrete_gpu(GPU) -> GpuCF=0.6 ; GpuCF=0.2)
    ; Workload == graphics -> (discrete_gpu(GPU) -> GpuCF=1.0 ; GpuCF=0.3)
    ; Workload == programming -> (discrete_gpu(GPU) -> GpuCF=0.8 ; integrated_gpu(GPU) -> GpuCF=0.7 ; GpuCF=0.6)
    ; Workload == ios_development -> GpuCF = 0.8
    ; (integrated_gpu(GPU) -> GpuCF=1.0 ; discrete_gpu(GPU) -> GpuCF=0.8 ; GpuCF=0.7) ).

calculate_battery_cf(Battery, Workload, BatteryCF) :-
    ( Workload == office -> (long_battery_life(Battery) -> BatteryCF=1.0 ; battery_mid(Battery) -> BatteryCF=0.8 ; BatteryCF=0.5)
    ; Workload == gaming -> (long_battery_life(Battery) -> BatteryCF=0.7 ; battery_mid(Battery) -> BatteryCF=0.6 ; BatteryCF=0.5)
    ; (long_battery_life(Battery) -> BatteryCF=0.9 ; battery_mid(Battery) -> BatteryCF=0.7 ; BatteryCF=0.4) ).

calculate_weight_cf(Weight, Workload, WeightCF) :-
    ( Workload == office -> (Weight =< 1.3 -> WeightCF=1.0 ; Weight =< 1.6 -> WeightCF=0.85 ; WeightCF=0.5)
    ; Workload == gaming -> (Weight =< 2.3 -> WeightCF=0.9 ; Weight =< 2.8 -> WeightCF=0.8 ; WeightCF=0.6)
    ; (Weight =< 1.5 -> WeightCF=0.9 ; Weight =< 2.0 -> WeightCF=0.8 ; WeightCF=0.5) ).


% ============================================================
% 7) BACKWARD CHAINING - Main inference engine
% ============================================================

recommend_laptop(Workload, Budget, ExtraRequirements, Name, Price, TotalCF) :-
    normalize_need(Workload, NormalizedWorkload),
    normalize_requirements(ExtraRequirements, NormalizedRequirements),
    laptop(Name, _Brand, Price, CPU, GPU, Ram, Ssd, _Screen, _Battery, _Weight),
    minimum_requirements(NormalizedWorkload, RequiredRam, RequiredSsd),
    matches_workload(NormalizedWorkload, CPU, GPU, Ram, Ssd),
    resolve_conflicts(NormalizedWorkload, Budget, NormalizedRequirements, EffectiveRequirements, _Warning),
    meets_extra_requirements(Name, EffectiveRequirements),
    total_cf(Name, NormalizedWorkload, Budget, RequiredRam, RequiredSsd, EffectiveRequirements, TotalCF),
    TotalCF >= 0.7.

tu_van_laptop(Workload, Budget, ExtraRequirements, Name, Price, TotalCF) :-
    recommend_laptop(Workload, Budget, ExtraRequirements, Name, Price, TotalCF).

% ============================================================
% 8) RESULT PROCESSING (SORT & TOP K)
% ============================================================

compare_cf_descending(D, CF1-Ten1-_, CF2-Ten2-_) :-
    compare(R, CF2, CF1),
    ( R == (=) -> compare(D, Ten1, Ten2) ; D = R ).

take_k_items(0, _, []) :- !.
take_k_items(_, [], []) :- !.
take_k_items(K, [H|T], [H|R]) :-
    K > 0,
    K1 is K - 1,
    take_k_items(K1, T, R).

best_recommendation(Workload, Budget, ExtraRequirements, Name, Price, CF) :-
    normalize_need(Workload, NormalizedWorkload),
    normalize_requirements(ExtraRequirements, NormalizedRequirements),
    findall(CF0-Ten0-Gia0,
            recommend_laptop(NormalizedWorkload, Budget, NormalizedRequirements, Ten0, Gia0, CF0),
            DS),
    DS \= [],
    predsort(compare_cf_descending, DS, [CF-Name-Price|_]).

top_k_recommendations(Workload, Budget, ExtraRequirements, K, TopK, Warning) :-
    explain_top_k_recommendations(Workload, Budget, ExtraRequirements, K, TopK, Warning).

recommend_top_k(Workload, Budget, ExtraRequirements, K, TopK, Warning) :-
    top_k_recommendations(Workload, Budget, ExtraRequirements, K, TopK, Warning).

explain_top_k_recommendations(Workload, Budget, ExtraRequirements, K, TopK, Warning) :-
    normalize_need(Workload, NormalizedWorkload),
    normalize_requirements(ExtraRequirements, NormalizedRequirements),
    resolve_conflicts(NormalizedWorkload, Budget, NormalizedRequirements, _, Warning),
    findall(CF0-Ten0-Gia0,
            recommend_laptop(NormalizedWorkload, Budget, NormalizedRequirements, Ten0, Gia0, CF0),
            DS),
    predsort(compare_cf_descending, DS, SortedDS),
    take_k_items(K, SortedDS, TopK).


% Range-aware Top-K: filter candidates by price between MinBudget and MaxBudget.
explain_top_k_recommendations_in_range(Workload, MinBudget, MaxBudget, ExtraRequirements, K, TopK, Warning) :-
    normalize_need(Workload, NormalizedWorkload),
    normalize_requirements(ExtraRequirements, NormalizedRequirements),
    % Use MaxBudget as the budget parameter when computing CF, but only include
    % laptops whose price falls within [MinBudget, MaxBudget].
    resolve_conflicts(NormalizedWorkload, MaxBudget, NormalizedRequirements, _, Warning),
    findall(CF0-Ten0-Gia0,
            (
                recommend_laptop(NormalizedWorkload, MaxBudget, NormalizedRequirements, Ten0, Gia0, CF0),
                Gia0 >= MinBudget,
                Gia0 =< MaxBudget
            ),
            DS),
    predsort(compare_cf_descending, DS, SortedDS),
    take_k_items(K, SortedDS, TopK).

% Wrapper to be called from Python when a min/max budget range is provided.
recommend_top_k_range(Workload, MinBudget, MaxBudget, ExtraRequirements, K, TopK, Warning) :-
    explain_top_k_recommendations_in_range(Workload, MinBudget, MaxBudget, ExtraRequirements, K, TopK, Warning).

tu_van_top_k_giai_thich(Workload, Budget, ExtraRequirements, K, TopK, Warning) :-
    explain_top_k_recommendations(Workload, Budget, ExtraRequirements, K, TopK, Warning).

% ============================================================
% 9) DEMO QUERY
% ============================================================

% Copy/paste this into the Prolog terminal to try it:
% ?- explain_top_k_recommendations(gaming, 35000000, [lightweight, preferred_brand('msi')], 3, Top3, Warning).