% ============================================================
%  laptop_advisor.pl (Complete Version)
%  Laptop purchase recommendation expert system
%  Includes: Fuzzy Logic + Heuristics (CPU suffix) + Brand CF
%            + Meta-rules (impossible budget) + Backward Chaining
%            + Ranking system and Top-K results.
% ============================================================

:- encoding(utf8).
:- consult('laptop_database.pl').

% ============================================================
% 1) GENERAL UTILITIES
% ============================================================

contains_ignore_case(Text, Key) :-
    downcase_atom(Text, T),
    downcase_atom(Key, K),
    sub_string(T, _, _, _, K).

chua_chuoi_khong_phan_biet_hoa_thuong(Text, Key) :-
    contains_ignore_case(Text, Key).

clamp01(X, 0.0) :- X < 0, !.
clamp01(X, 1.0) :- X > 1, !.
clamp01(X, X).

remove_item(_, [], []).
remove_item(X, [X|T], R) :- !, remove_item(X, T, R).
remove_item(X, [H|T], [H|R]) :- remove_item(X, T, R).

xoa_phan_tu(X, List, Result) :-
    remove_item(X, List, Result).

normalize_requirement_list([], []) :- !.
normalize_requirement_list([H|T], [H|T]) :- !.
normalize_requirement_list(Atom, [Atom]).

chuan_hoa_yeu_cau(List, Normalized) :-
    normalize_requirement_list(List, Normalized).

normalize_need(office, van_phong).
normalize_need(programming, lap_trinh).
normalize_need(ios_development, lap_trinh_ios).
normalize_need(graphics, do_hoa).
normalize_need(gaming, gaming).
normalize_need(ai_data_science, ai_data_science).
normalize_need(van_phong, van_phong).
normalize_need(lap_trinh, lap_trinh).
normalize_need(lap_trinh_ios, lap_trinh_ios).
normalize_need(do_hoa, do_hoa).

normalize_requirement(lightweight, mong_nhe).
normalize_requirement(long_battery_life, pin_trau).
normalize_requirement(budget_friendly, gia_re).
normalize_requirement(mid_range, tam_trung).
normalize_requirement(large_display, man_to).
normalize_requirement(discrete_gpu, gpu_roi).
normalize_requirement(integrated_gpu, gpu_onboard).
normalize_requirement(preferred_brand(Hang), thich_thuong_hieu(Hang)).
normalize_requirement(thich_thuong_hieu(Hang), thich_thuong_hieu(Hang)).
normalize_requirement(uu_tien_hieu_nang, uu_tien_hieu_nang).
normalize_requirement(gia_rat_re, gia_rat_re).
normalize_requirement(gia_re, gia_re).
normalize_requirement(tam_trung, tam_trung).
normalize_requirement(cao_cap, cao_cap).
normalize_requirement(mong_nhe, mong_nhe).
normalize_requirement(nang, nang).
normalize_requirement(man_nho, man_nho).
normalize_requirement(man_to, man_to).
normalize_requirement(man_vua, man_vua).
normalize_requirement(pin_trau, pin_trau).
normalize_requirement(gpu_roi, gpu_roi).
normalize_requirement(gpu_onboard, gpu_onboard).

normalize_requirements([], []).
normalize_requirements([H|T], [NH|NT]) :-
    normalize_requirement(H, NH),
    normalize_requirements(T, NT).
normalize_requirements(Atom, [Normalized]) :-
    Atom \= [],
    Atom \= [_|_],
    normalize_requirement(Atom, Normalized).

soft_property(Name, Property) :-
    thuoc_tinh_mo(Name, Property).

minimum_requirements(Workload, RequiredRam, RequiredSsd) :-
    yeu_cau_toi_thieu(Workload, RequiredRam, RequiredSsd).

matches_workload(Workload, CPU, GPU, RAM, SSD) :-
    dap_ung_nhu_cau(Workload, CPU, GPU, RAM, SSD).

resolve_conflicts(Workload, Budget, Requirements, EffectiveRequirements, Warning) :-
    sieu_luat_xung_dot(Workload, Budget, Requirements, EffectiveRequirements, Warning).

total_cf(Name, Workload, Budget, RequiredRam, RequiredSsd, EffectiveRequirements, TotalCF) :-
    tinh_cf_tong(Name, Workload, Budget, RequiredRam, RequiredSsd, EffectiveRequirements, TotalCF).

% ============================================================
% 2) FUZZY LOGIC - Soft rules (numeric -> qualitative)
% ============================================================

% ---- Price fuzziness ----
gia_rat_re(Gia) :- Gia =< 15000000.
gia_re(Gia)     :- Gia > 15000000, Gia =< 25000000.
tam_trung(Gia)  :- Gia > 25000000, Gia =< 40000000.
cao_cap(Gia)    :- Gia > 40000000.

% ---- Weight fuzziness ----
rat_nhe(KL)  :- KL =< 1.2.
mong_nhe(KL) :- KL > 1.2, KL =< 1.5.
can_bang(KL) :- KL > 1.5, KL =< 2.0.
nang(KL)     :- KL > 2.0.

% ---- Display fuzziness ----
man_nho(Man) :- Man < 14.0.
man_vua(Man) :- Man >= 14.0, Man =< 15.6.
man_to(Man)  :- Man > 15.6.

% ---- Battery fuzziness ----
pin_yeu(Pin)        :- Pin < 50.
pin_trung_binh(Pin) :- Pin >= 50, Pin < 70.
pin_trau(Pin)       :- Pin >= 70.

% ---- Soft labels for each laptop ----
thuoc_tinh_mo(Ten, gia_rat_re) :- laptop(Ten, _, Gia, _, _, _, _, _, _, _), gia_rat_re(Gia).
thuoc_tinh_mo(Ten, gia_re)     :- laptop(Ten, _, Gia, _, _, _, _, _, _, _), gia_re(Gia).
thuoc_tinh_mo(Ten, tam_trung)  :- laptop(Ten, _, Gia, _, _, _, _, _, _, _), tam_trung(Gia).
thuoc_tinh_mo(Ten, cao_cap)    :- laptop(Ten, _, Gia, _, _, _, _, _, _, _), cao_cap(Gia).

thuoc_tinh_mo(Ten, mong_nhe)   :- laptop(Ten, _, _, _, _, _, _, _, _, KL), mong_nhe(KL).
thuoc_tinh_mo(Ten, nang)       :- laptop(Ten, _, _, _, _, _, _, _, _, KL), nang(KL).

thuoc_tinh_mo(Ten, man_nho)    :- laptop(Ten, _, _, _, _, _, _, Man, _, _), man_nho(Man).
thuoc_tinh_mo(Ten, man_to)     :- laptop(Ten, _, _, _, _, _, _, Man, _, _), man_to(Man).

thuoc_tinh_mo(Ten, pin_trau)   :- laptop(Ten, _, _, _, _, _, _, _, Pin, _), pin_trau(Pin).

% ============================================================
% 3) HEURISTICS - Experience-based rules by workload
% ============================================================

% ---- GPU detection ----
gpu_roi(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx').
gpu_roi(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'gtx').
gpu_roi(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'geforce mx').
gpu_roi(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'radeon rx').
gpu_roi(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'radeon 8060s').

gpu_onboard(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'intel graphics').
gpu_onboard(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'intel iris').
gpu_onboard(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'intel uhd').
gpu_onboard(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'apple').
gpu_onboard(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'amd radeon graphics').
gpu_onboard(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'qualcomm').

% ---- CPU suffix detection ----
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'h').
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'hx').
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'pro').
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'max').
% ---- Add newer AMD chips (without H suffix) ----
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ryzen ai').
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ryzen 7 260').
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ryzen 7 250').

% ---- Basic CPU strength classification ----
cpu_co_ban(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'i3').
cpu_co_ban(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'core 3').

cpu_trung_binh(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'i5').
cpu_trung_binh(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ryzen 5').
cpu_trung_binh(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ultra 5').

cpu_manh(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'i7').
cpu_manh(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'i9').
cpu_manh(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ultra 7').
cpu_manh(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ryzen 7').
cpu_manh(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ryzen 9').
cpu_manh(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'apple m').
cpu_manh(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'snapdragon x').

cpu_du_dung(CPU) :- cpu_co_ban(CPU) ; cpu_trung_binh(CPU) ; cpu_manh(CPU).

% ---- Strong GPUs for gaming ----
gpu_gaming_manh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 3070').
gpu_gaming_manh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 3080').
gpu_gaming_manh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4070').
gpu_gaming_manh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4080').
gpu_gaming_manh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4090').

% ---- High-end discrete GPUs ----
gpu_roi_cao_cap(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4050').
gpu_roi_cao_cap(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4060').
gpu_roi_cao_cap(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 3060').
gpu_roi_cao_cap(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'radeon rx 6700').
gpu_roi_cao_cap(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'radeon 6600m').

% ---- Mid-range discrete GPUs ----
gpu_roi_trung_binh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'geforce mx 550').
gpu_roi_trung_binh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'gtx 1650').
gpu_roi_trung_binh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'gtx 1660').

% ---- GPU accelerators for AI / Machine Learning ----
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4090').
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4080').
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4070').
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 3080').
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 3070').
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4060').


% ---- Minimum configuration by workload ----
yeu_cau_toi_thieu(van_phong, 8, 256).
yeu_cau_toi_thieu(lap_trinh, 16, 512).
yeu_cau_toi_thieu(lap_trinh_ios, 16, 512).
yeu_cau_toi_thieu(do_hoa, 16, 512).
yeu_cau_toi_thieu(gaming, 16, 512).
yeu_cau_toi_thieu(ai_data_science, 16, 512).

% ---- Workload filters ----
dap_ung_nhu_cau(van_phong, CPU, _GPU, RAM, SSD) :-
    RAM >= 8, SSD >= 256, cpu_du_dung(CPU).

dap_ung_nhu_cau(lap_trinh, CPU, _GPU, RAM, SSD) :-
    RAM >= 16, SSD >= 512, (cpu_trung_binh(CPU) ; cpu_manh(CPU)).

dap_ung_nhu_cau(lap_trinh_ios, CPU, _GPU, RAM, SSD) :-
    RAM >= 16, SSD >= 512, chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'apple').

dap_ung_nhu_cau(do_hoa, CPU, GPU, RAM, SSD) :-
    RAM >= 16, SSD >= 512,
    ( (gpu_roi(GPU), cpu_hieu_nang_cao(CPU)) ; chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'apple') ).

dap_ung_nhu_cau(gaming, CPU, GPU, RAM, SSD) :-
    RAM >= 16, SSD >= 512, gpu_roi(GPU), 
    (gpu_gaming_manh(GPU) ; gpu_roi_cao_cap(GPU)),
    cpu_hieu_nang_cao(CPU).


% ---- Requirements for AI / Data Science ----
dap_ung_nhu_cau(ai_data_science, CPU, GPU, RAM, SSD) :-
    RAM >= 32, SSD >= 512,
    ( gpu_ai_accelerator(GPU) ; cpu_manh(CPU) ).


% ============================================================
% 4) META-RULES - Conflict resolution
% ============================================================

sieu_luat_xung_dot(NhuCau, NganSach, YeuCauThemVao, YeuCauThemRa, CanhBaoTong) :-
    normalize_need(NhuCau, NhuCauN),
    normalize_requirements(YeuCauThemVao, Y0),
    xu_ly_xd_ngan_sach(NhuCauN, NganSach, C0),
    xu_ly_xd_gaming_mong_nhe(NhuCauN, Y0, Y1, C1),
    xu_ly_xd_do_hoa_gia_re(NhuCauN, Y1, Y2, C2),
    xu_ly_xd_gaming_pin_trau(NhuCauN, Y2, Y3, C3),
    xu_ly_xd_man_to_mong_nhe(_NhuCau, Y3, Y4, C4),
    xu_ly_xd_hieu_nang_gpu_onboard(NhuCauN, Y4, YeuCauThemRa, C5),
    gop_canh_bao([C0, C1, C2, C3, C4, C5], CanhBaoTong).

xu_ly_xd_ngan_sach(NhuCau, NganSach, CanhBao) :-
    ( (NhuCau == gaming ; NhuCau == do_hoa), NganSach > 0, NganSach < 15000000 ->
        CanhBao = 'Warning: budgets below VND 15 million make it hard to find a new laptop that fits gaming/graphics well.'
    ; NhuCau == lap_trinh_ios, NganSach > 0, NganSach < 18000000 ->
        CanhBao = 'Warning: MacBooks that work well for iOS development often cost more than VND 18 million, so this budget may be too low.'
    ; CanhBao = none ).

xu_ly_xd_gaming_mong_nhe(NhuCau, Yin, Yout, CanhBao) :-
    ( NhuCau == gaming, member(mong_nhe, Yin) ->
        xoa_phan_tu(mong_nhe, Yin, Ytmp), Yout = [uu_tien_hieu_nang|Ytmp],
        CanhBao = 'Conflict: gaming + lightweight. The system drops lightweight and prioritizes performance.'
    ; Yout = Yin, CanhBao = none ).

xu_ly_xd_do_hoa_gia_re(NhuCau, Yin, Yout, CanhBao) :-
    ( NhuCau == do_hoa, member(gia_re, Yin) ->
        xoa_phan_tu(gia_re, Yin, Ytmp), Yout = [tam_trung|Ytmp],
        CanhBao = 'Conflict: graphics + budget-friendly. The system upgrades to mid-range to preserve GPU performance.'
    ; Yout = Yin, CanhBao = none ).

xu_ly_xd_gaming_pin_trau(NhuCau, Yin, Yout, CanhBao) :-
    ( NhuCau == gaming, member(pin_trau, Yin) ->
        Yout = Yin, CanhBao = 'Warning: gaming + long battery life is difficult to optimize at the same time.'
    ; Yout = Yin, CanhBao = none ).

xu_ly_xd_man_to_mong_nhe(_NhuCau, Yin, Yout, CanhBao) :-
    ( member(man_to, Yin), member(mong_nhe, Yin) ->
        xoa_phan_tu(man_to, Yin, Ytmp), Yout = [man_vua|Ytmp],
        CanhBao = 'Conflict: large display + lightweight. The system downgrades the display size to medium.'
    ; Yout = Yin, CanhBao = none ).

xu_ly_xd_hieu_nang_gpu_onboard(NhuCau, Yin, Yout, CanhBao) :-
    ( member(gpu_onboard, Yin), (NhuCau == gaming ; NhuCau == do_hoa) ->
        xoa_phan_tu(gpu_onboard, Yin, Ytmp), Yout = [gpu_roi|Ytmp],
        CanhBao = 'Conflict: high-performance workloads should not use integrated GPU. The system switches to discrete GPU.'
    ; Yout = Yin, CanhBao = none ).

gop_canh_bao([], []).
gop_canh_bao([none|T], R) :- !, gop_canh_bao(T, R).
gop_canh_bao([H|T], [H|R]) :- gop_canh_bao(T, R).


% ============================================================
% 5) Check extra requirements after meta-rules
% ============================================================

meets_extra_requirements(_Name, []).
meets_extra_requirements(Name, [H|T]) :- normalize_requirement(H, N), meets_one_requirement(Name, N), meets_extra_requirements(Name, T).
meets_extra_requirements(Name, Atom) :- Atom \= [], Atom \= [_|_], normalize_requirement(Atom, N), meets_one_requirement(Name, N).

thoa_yeu_cau_them(Name, Requirements) :-
    meets_extra_requirements(Name, Requirements).

meets_one_requirement(_Name, performance_priority).
meets_one_requirement(_Name, thich_thuong_hieu(_)).
meets_one_requirement(_Name, preferred_brand(_)).

meets_one_requirement(Name, cheap_price) :- soft_property(Name, cheap_price).
meets_one_requirement(Name, budget_friendly) :- soft_property(Name, budget_friendly).
meets_one_requirement(Name, mid_range) :- soft_property(Name, mid_range).
meets_one_requirement(Name, high_end) :- soft_property(Name, high_end).
meets_one_requirement(Name, lightweight) :- soft_property(Name, lightweight).
meets_one_requirement(Name, heavy) :- soft_property(Name, heavy).
meets_one_requirement(Name, small_display) :- soft_property(Name, small_display).
meets_one_requirement(Name, large_display) :- soft_property(Name, large_display).
meets_one_requirement(Name, medium_display) :- laptop(Name, _, _, _, _, _, _, Screen, _, _), man_vua(Screen).
meets_one_requirement(Name, long_battery_life) :- soft_property(Name, long_battery_life).

meets_one_requirement(Name, brand(Hang)) :- laptop(Name, Hang, _, _, _, _, _, _, _, _).
meets_one_requirement(Name, preferred_brand(Hang)) :- laptop(Name, Hang, _, _, _, _, _, _, _, _).
meets_one_requirement(Name, discrete_gpu) :- laptop(Name, _, _, _, GPU, _, _, _, _, _), gpu_roi(GPU).
meets_one_requirement(Name, integrated_gpu) :- laptop(Name, _, _, _, GPU, _, _, _, _, _), gpu_onboard(GPU).

thoa_mot_yeu_cau(Name, Requirement) :-
    meets_one_requirement(Name, Requirement).


% ============================================================
% 6) CERTAINTY FACTOR (CF)
% ============================================================

tinh_diem_cf(GiaMay, NganSach, CF_Gia) :-
    ( NganSach =< 0 -> CF_Gia = 0.0
    ; GiaMay =< NganSach ->
        TiLe is GiaMay / NganSach, Raw is 0.6 + 0.4 * TiLe, clamp01(Raw, CF_Gia)
    ; Vuot is (GiaMay - NganSach) / NganSach, Raw is 1.0 - 1.5 * Vuot, clamp01(Raw, CF_Gia) ).

cf_thuong_ram(Ram, RamYC, CF_Ram) :-
    ( RamYC =< 0 -> CF_Ram = 0.0 ; TiLe is Ram / RamYC,
      ( TiLe >= 2.0 -> CF_Ram = 1.0 ; TiLe >= 1.5 -> CF_Ram = 0.9 ; TiLe >= 1.0 -> CF_Ram = 0.7 ; CF_Ram = 0.2 )).

cf_thuong_ssd(Ssd, SsdYC, CF_Ssd) :-
    ( SsdYC =< 0 -> CF_Ssd = 0.0 ; TiLe is Ssd / SsdYC,
      ( TiLe >= 2.0 -> CF_Ssd = 1.0 ; TiLe >= 1.5 -> CF_Ssd = 0.9 ; TiLe >= 1.0 -> CF_Ssd = 0.75 ; CF_Ssd = 0.2 )).

cf_gpu_theo_nhu_cau(GPU, NhuCau, CF_GPU) :-
    ( NhuCau == ai_data_science -> (
          ( gpu_ai_accelerator(GPU) -> CF_GPU = 1.0
          ; gpu_roi_cao_cap(GPU)       -> CF_GPU = 0.9
          ; gpu_roi_trung_binh(GPU)    -> CF_GPU = 0.6
          ; gpu_onboard(GPU)           -> CF_GPU = 0.3
          ; CF_GPU = 0.5 )
      )
    ; NhuCau == gaming -> (gpu_gaming_manh(GPU) -> CF_GPU=1.0 ; gpu_roi_cao_cap(GPU) -> CF_GPU=0.75 ; gpu_roi_trung_binh(GPU) -> CF_GPU=0.4 ; gpu_roi(GPU) -> CF_GPU=0.6 ; CF_GPU=0.2)
    ; NhuCau == do_hoa -> (gpu_roi(GPU) -> CF_GPU=1.0 ; CF_GPU=0.3)
    ; NhuCau == lap_trinh -> (gpu_roi(GPU) -> CF_GPU=0.8 ; gpu_onboard(GPU) -> CF_GPU=0.7 ; CF_GPU=0.6)
    ; NhuCau == lap_trinh_ios -> CF_GPU = 0.8
    ; (gpu_onboard(GPU) -> CF_GPU=1.0 ; gpu_roi(GPU) -> CF_GPU=0.8 ; CF_GPU=0.7) ).

cf_pin_theo_nhu_cau(Pin, NhuCau, CF_Pin) :-
    ( NhuCau == van_phong -> (pin_trau(Pin) -> CF_Pin=1.0 ; pin_trung_binh(Pin) -> CF_Pin=0.8 ; CF_Pin=0.5)
    ; NhuCau == gaming -> (pin_trau(Pin) -> CF_Pin=0.7 ; pin_trung_binh(Pin) -> CF_Pin=0.6 ; CF_Pin=0.5)
    ; (pin_trau(Pin) -> CF_Pin=0.9 ; pin_trung_binh(Pin) -> CF_Pin=0.7 ; CF_Pin=0.4) ).

cf_khoi_luong_theo_nhu_cau(KL, NhuCau, CF_KL) :-
    ( NhuCau == van_phong -> (KL =< 1.3 -> CF_KL=1.0 ; KL =< 1.6 -> CF_KL=0.85 ; CF_KL=0.5)
    ; NhuCau == gaming -> (KL =< 2.3 -> CF_KL=0.9 ; KL =< 2.8 -> CF_KL=0.8 ; CF_KL=0.6)
    ; (KL =< 1.5 -> CF_KL=0.9 ; KL =< 2.0 -> CF_KL=0.8 ; CF_KL=0.5) ).

brand_bonus(Name, Requirements, Bonus) :-
    ( member(thich_thuong_hieu(FavBrand), Requirements), laptop(Name, FavBrand, _, _, _, _, _, _, _, _) ->
        Bonus = 0.15
    ; Bonus = 0.0 ).

diem_thuong_thuong_hieu(Name, Requirements, Bonus) :-
    brand_bonus(Name, Requirements, Bonus).

tinh_cf_tong(Name, Workload, Budget, RequiredRam, RequiredSsd, EffectiveRequirements, TotalCF) :-
    laptop(Name, _, Price, _CPU, GPU, Ram, Ssd, _Screen, Battery, Weight),
    price_cf(Price, Budget, PriceCF),
    ram_bonus_cf(Ram, RequiredRam, RamCF),
    ssd_bonus_cf(Ssd, RequiredSsd, SsdCF),
    gpu_workload_cf(GPU, Workload, GpuCF),
    battery_workload_cf(Battery, Workload, BatteryCF),
    weight_workload_cf(Weight, Workload, WeightCF),
    brand_bonus(Name, EffectiveRequirements, BrandBonus),
    
    Raw is 0.35*PriceCF + 0.15*RamCF + 0.10*SsdCF + 0.20*GpuCF + 0.10*BatteryCF + 0.10*WeightCF + BrandBonus,
    clamp01(Raw, TotalCF).

price_cf(Price, Budget, PriceCF) :- tinh_diem_cf(Price, Budget, PriceCF).
ram_bonus_cf(Ram, RequiredRam, RamCF) :- cf_thuong_ram(Ram, RequiredRam, RamCF).
ssd_bonus_cf(Ssd, RequiredSsd, SsdCF) :- cf_thuong_ssd(Ssd, RequiredSsd, SsdCF).
gpu_workload_cf(GPU, Workload, GpuCF) :- cf_gpu_theo_nhu_cau(GPU, Workload, GpuCF).
battery_workload_cf(Battery, Workload, BatteryCF) :- cf_pin_theo_nhu_cau(Battery, Workload, BatteryCF).
weight_workload_cf(Weight, Workload, WeightCF) :- cf_khoi_luong_theo_nhu_cau(Weight, Workload, WeightCF).


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

so_sanh_cf_giam_dan(D, Left, Right) :-
    compare_cf_descending(D, Left, Right).

take_k_items(0, _, []) :- !.
take_k_items(_, [], []) :- !.
take_k_items(K, [H|T], [H|R]) :-
    K > 0,
    K1 is K - 1,
    take_k_items(K1, T, R).

lay_k_phan_tu(K, List, Result) :-
    take_k_items(K, List, Result).

best_recommendation(Workload, Budget, ExtraRequirements, Name, Price, CF) :-
    normalize_need(Workload, NormalizedWorkload),
    normalize_requirements(ExtraRequirements, NormalizedRequirements),
    findall(CF0-Ten0-Gia0,
            recommend_laptop(NormalizedWorkload, Budget, NormalizedRequirements, Ten0, Gia0, CF0),
            DS),
    DS \= [],
    predsort(compare_cf_descending, DS, [CF-Name-Price|_]).

tu_van_tot_nhat(Workload, Budget, ExtraRequirements, Name, Price, CF) :-
    best_recommendation(Workload, Budget, ExtraRequirements, Name, Price, CF).

% ---> Main predicate called by Python <---
recommend_best(NhuCau, NganSach, YeuCauThem, Ten, Gia, CF) :-
    tu_van_tot_nhat(NhuCau, NganSach, YeuCauThem, Ten, Gia, CF).

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