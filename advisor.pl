% ============================================================
%  advisor.pl (Phiên bản Hoàn Chỉnh Tuyệt Đối)
%  He chuyen gia tu van chon mua laptop
%  Bao gom: Fuzzy Logic + Heuristics (CPU Suffix) + CF (Brand) 
%           + Meta-rules (Impossible Budget) + Backward Chaining
%           + He thong sap xep va lay Top K ket qua.
% ============================================================

:- encoding(utf8).
:- consult('db.pl').

% ============================================================
% 1) TIEN ICH CHUNG
% ============================================================

chua_chuoi_khong_phan_biet_hoa_thuong(Text, Key) :-
    downcase_atom(Text, T),
    downcase_atom(Key, K),
    sub_string(T, _, _, _, K).

clamp01(X, 0.0) :- X < 0, !.
clamp01(X, 1.0) :- X > 1, !.
clamp01(X, X).

xoa_phan_tu(_, [], []).
xoa_phan_tu(X, [X|T], R) :- !, xoa_phan_tu(X, T, R).
xoa_phan_tu(X, [H|T], [H|R]) :- xoa_phan_tu(X, T, R).

chuan_hoa_yeu_cau([], []) :- !.
chuan_hoa_yeu_cau([H|T], [H|T]) :- !.
chuan_hoa_yeu_cau(Atom, [Atom]).

% ============================================================
% 2) FUZZY LOGIC - Luat mo (dinh luong -> dinh tinh)
% ============================================================

% ---- Fuzzy gia ----
gia_rat_re(Gia) :- Gia =< 15000000.
gia_re(Gia)     :- Gia > 15000000, Gia =< 25000000.
tam_trung(Gia)  :- Gia > 25000000, Gia =< 40000000.
cao_cap(Gia)    :- Gia > 40000000.

% ---- Fuzzy khoi luong ----
rat_nhe(KL)  :- KL =< 1.2.
mong_nhe(KL) :- KL > 1.2, KL =< 1.5.
can_bang(KL) :- KL > 1.5, KL =< 2.0.
nang(KL)     :- KL > 2.0.

% ---- Fuzzy man hinh ----
man_nho(Man) :- Man < 14.0.
man_vua(Man) :- Man >= 14.0, Man =< 15.6.
man_to(Man)  :- Man > 15.6.

% ---- Fuzzy pin ----
pin_yeu(Pin)        :- Pin < 50.
pin_trung_binh(Pin) :- Pin >= 50, Pin < 70.
pin_trau(Pin)       :- Pin >= 70.

% ---- Gan nhan mo tren tung laptop ----
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
% 3) HEURISTICS - Luat kinh nghiem theo nhu cau
% ============================================================

% ---- Nhan dien GPU ----
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

% ---- Nhan dien Hau to CPU ----
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'h').
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'hx').
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'pro').
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'max').
% ---- Bo sung cac chip AMD doi moi (khong co hau to H) ----
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ryzen ai').
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ryzen 7 260').
cpu_hieu_nang_cao(CPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(CPU, 'ryzen 7 250').

% ---- Danh gia suc manh CPU co ban ----
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

% ---- GPU manh cho gaming ----
gpu_gaming_manh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 3070').
gpu_gaming_manh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 3080').
gpu_gaming_manh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4070').
gpu_gaming_manh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4080').
gpu_gaming_manh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4090').

% ---- GPU roi cao cap ----
gpu_roi_cao_cap(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4050').
gpu_roi_cao_cap(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4060').
gpu_roi_cao_cap(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 3060').
gpu_roi_cao_cap(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'radeon rx 6700').
gpu_roi_cao_cap(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'radeon 6600m').

% ---- GPU roi trung binh ----
gpu_roi_trung_binh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'geforce mx 550').
gpu_roi_trung_binh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'gtx 1650').
gpu_roi_trung_binh(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'gtx 1660').

% ---- GPU accelerator cho AI/Machine Learning ----
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4090').
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4080').
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4070').
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 3080').
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 3070').
gpu_ai_accelerator(GPU) :- chua_chuoi_khong_phan_biet_hoa_thuong(GPU, 'rtx 4060').


% ---- Cau hinh toi thieu theo nhu cau ----
yeu_cau_toi_thieu(van_phong, 8, 256).
yeu_cau_toi_thieu(lap_trinh, 16, 512).
yeu_cau_toi_thieu(lap_trinh_ios, 16, 512).
yeu_cau_toi_thieu(do_hoa, 16, 512).
yeu_cau_toi_thieu(gaming, 16, 512).
yeu_cau_toi_thieu(ai_data_science, 16, 512).

% ---- Bo loc theo nhu cau ----
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


% ---- Dap ung cho nhu cau AI / Data Science ----
dap_ung_nhu_cau(ai_data_science, CPU, GPU, RAM, SSD) :-
    RAM >= 32, SSD >= 512,
    ( gpu_ai_accelerator(GPU) ; cpu_manh(CPU) ).


% ============================================================
% 4) META-RULES - Giai quyet xung dot
% ============================================================

sieu_luat_xung_dot(NhuCau, NganSach, YeuCauThemVao, YeuCauThemRa, CanhBaoTong) :-
    chuan_hoa_yeu_cau(YeuCauThemVao, Y0),
    xu_ly_xd_ngan_sach(NhuCau, NganSach, C0),
    xu_ly_xd_gaming_mong_nhe(NhuCau, Y0, Y1, C1),
    xu_ly_xd_do_hoa_gia_re(NhuCau, Y1, Y2, C2),
    xu_ly_xd_gaming_pin_trau(NhuCau, Y2, Y3, C3),
    xu_ly_xd_man_to_mong_nhe(_NhuCau, Y3, Y4, C4),
    xu_ly_xd_hieu_nang_gpu_onboard(NhuCau, Y4, YeuCauThemRa, C5),
    gop_canh_bao([C0, C1, C2, C3, C4, C5], CanhBaoTong).

xu_ly_xd_ngan_sach(NhuCau, NganSach, CanhBao) :-
    ( (NhuCau == gaming ; NhuCau == do_hoa), NganSach > 0, NganSach < 15000000 ->
        CanhBao = 'Canh bao: Ngan sach duoi 15 trieu rat kho tim may moi dap ung tot Gaming/Do hoa.'
    ; NhuCau == lap_trinh_ios, NganSach > 0, NganSach < 18000000 ->
        CanhBao = 'Canh bao: MacBook dap ung tot lap trinh iOS thuong co gia tren 18 trieu, ngan sach nay hoi thap.'
    ; CanhBao = none ).

xu_ly_xd_gaming_mong_nhe(NhuCau, Yin, Yout, CanhBao) :-
    ( NhuCau == gaming, member(mong_nhe, Yin) ->
        xoa_phan_tu(mong_nhe, Yin, Ytmp), Yout = [uu_tien_hieu_nang|Ytmp],
        CanhBao = 'Xung dot: gaming + mong_nhe. He thong bo qua mong_nhe, uu tien hieu nang.'
    ; Yout = Yin, CanhBao = none ).

xu_ly_xd_do_hoa_gia_re(NhuCau, Yin, Yout, CanhBao) :-
    ( NhuCau == do_hoa, member(gia_re, Yin) ->
        xoa_phan_tu(gia_re, Yin, Ytmp), Yout = [tam_trung|Ytmp],
        CanhBao = 'Xung dot: do_hoa + gia_re. He thong nang len tam_trung de dam bao GPU.'
    ; Yout = Yin, CanhBao = none ).

xu_ly_xd_gaming_pin_trau(NhuCau, Yin, Yout, CanhBao) :-
    ( NhuCau == gaming, member(pin_trau, Yin) ->
        Yout = Yin, CanhBao = 'Canh bao: gaming + pin_trau kho dong thoi toi uu.'
    ; Yout = Yin, CanhBao = none ).

xu_ly_xd_man_to_mong_nhe(_NhuCau, Yin, Yout, CanhBao) :-
    ( member(man_to, Yin), member(mong_nhe, Yin) ->
        xoa_phan_tu(man_to, Yin, Ytmp), Yout = [man_vua|Ytmp],
        CanhBao = 'Xung dot: man_to + mong_nhe. He thong doi man_to -> man_vua.'
    ; Yout = Yin, CanhBao = none ).

xu_ly_xd_hieu_nang_gpu_onboard(NhuCau, Yin, Yout, CanhBao) :-
    ( member(gpu_onboard, Yin), (NhuCau == gaming ; NhuCau == do_hoa) ->
        xoa_phan_tu(gpu_onboard, Yin, Ytmp), Yout = [gpu_roi|Ytmp],
        CanhBao = 'Xung dot: Hieu nang cao khong dung gpu_onboard. He thong doi sang gpu_roi.'
    ; Yout = Yin, CanhBao = none ).

gop_canh_bao([], []).
gop_canh_bao([none|T], R) :- !, gop_canh_bao(T, R).
gop_canh_bao([H|T], [H|R]) :- gop_canh_bao(T, R).


% ============================================================
% 5) Kiem tra YeuCauThem sau khi qua Meta-rules
% ============================================================

thoa_yeu_cau_them(_Ten, []).
thoa_yeu_cau_them(Ten, [H|T]) :- thoa_mot_yeu_cau(Ten, H), thoa_yeu_cau_them(Ten, T).
thoa_yeu_cau_them(Ten, Atom) :- Atom \= [], Atom \= [_|_], thoa_mot_yeu_cau(Ten, Atom).

thoa_mot_yeu_cau(_Ten, uu_tien_hieu_nang).
thoa_mot_yeu_cau(_Ten, thich_thuong_hieu(_)). 

thoa_mot_yeu_cau(Ten, gia_rat_re) :- thuoc_tinh_mo(Ten, gia_rat_re).
thoa_mot_yeu_cau(Ten, gia_re)     :- thuoc_tinh_mo(Ten, gia_re).
thoa_mot_yeu_cau(Ten, tam_trung)  :- thuoc_tinh_mo(Ten, tam_trung).
thoa_mot_yeu_cau(Ten, cao_cap)    :- thuoc_tinh_mo(Ten, cao_cap).
thoa_mot_yeu_cau(Ten, mong_nhe)   :- thuoc_tinh_mo(Ten, mong_nhe).
thoa_mot_yeu_cau(Ten, nang)       :- thuoc_tinh_mo(Ten, nang).
thoa_mot_yeu_cau(Ten, man_nho)    :- thuoc_tinh_mo(Ten, man_nho).
thoa_mot_yeu_cau(Ten, man_to)     :- thuoc_tinh_mo(Ten, man_to).
thoa_mot_yeu_cau(Ten, man_vua)    :- laptop(Ten, _, _, _, _, _, _, Man, _, _), man_vua(Man).
thoa_mot_yeu_cau(Ten, pin_trau)   :- thuoc_tinh_mo(Ten, pin_trau).

thoa_mot_yeu_cau(Ten, thuong_hieu(Hang)) :- laptop(Ten, Hang, _, _, _, _, _, _, _, _).
thoa_mot_yeu_cau(Ten, gpu_roi) :- laptop(Ten, _, _, _, GPU, _, _, _, _, _), gpu_roi(GPU).
thoa_mot_yeu_cau(Ten, gpu_onboard) :- laptop(Ten, _, _, _, GPU, _, _, _, _, _), gpu_onboard(GPU).


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

diem_thuong_thuong_hieu(Ten, YeuCauList, Bonus_Brand) :-
    ( member(thich_thuong_hieu(FavBrand), YeuCauList), laptop(Ten, FavBrand, _, _, _, _, _, _, _, _) ->
        Bonus_Brand = 0.15 
    ; Bonus_Brand = 0.0 ).

tinh_cf_tong(Ten, NhuCau, NganSach, RamYC, SsdYC, YeuCauHieuLuc, CF_Tong) :-
    laptop(Ten, _, Gia, _CPU, GPU, Ram, Ssd, _Man, Pin, KL),
    tinh_diem_cf(Gia, NganSach, CF_Gia),
    cf_thuong_ram(Ram, RamYC, CF_Ram),
    cf_thuong_ssd(Ssd, SsdYC, CF_Ssd),
    cf_gpu_theo_nhu_cau(GPU, NhuCau, CF_GPU),
    cf_pin_theo_nhu_cau(Pin, NhuCau, CF_Pin),
    cf_khoi_luong_theo_nhu_cau(KL, NhuCau, CF_KL),
    diem_thuong_thuong_hieu(Ten, YeuCauHieuLuc, Bonus_Brand),
    
    Raw is 0.35*CF_Gia + 0.15*CF_Ram + 0.10*CF_Ssd + 0.20*CF_GPU + 0.10*CF_Pin + 0.10*CF_KL + Bonus_Brand,
    clamp01(Raw, CF_Tong).


% ============================================================
% 7) BACKWARD CHAINING - Co may suy dien chinh
% ============================================================

tu_van_laptop(NhuCau, NganSach, YeuCauThem, Ten, Gia, CF_Tong) :-
    laptop(Ten, _Hang, Gia, CPU, GPU, Ram, Ssd, _Man, _Pin, _KL),
    yeu_cau_toi_thieu(NhuCau, RamYC, SsdYC),
    dap_ung_nhu_cau(NhuCau, CPU, GPU, Ram, Ssd),
    sieu_luat_xung_dot(NhuCau, NganSach, YeuCauThem, YeuCauHieuLuc, _CanhBao),
    thoa_yeu_cau_them(Ten, YeuCauHieuLuc),
    tinh_cf_tong(Ten, NhuCau, NganSach, RamYC, SsdYC, YeuCauHieuLuc, CF_Tong),
    CF_Tong >= 0.7.

% ============================================================
% 8) XU LY DANH SACH KET QUA (SORT & TOP K)
% ============================================================

so_sanh_cf_giam_dan(D, CF1-Ten1-_, CF2-Ten2-_) :-
    compare(R, CF2, CF1),
    ( R == (=) -> compare(D, Ten1, Ten2) ; D = R ).

lay_k_phan_tu(0, _, []) :- !.
lay_k_phan_tu(_, [], []) :- !.
lay_k_phan_tu(K, [H|T], [H|R]) :-
    K > 0,
    K1 is K - 1,
    lay_k_phan_tu(K1, T, R).

tu_van_tot_nhat(NhuCau, NganSach, YeuCauThem, Ten, Gia, CF) :-
    findall(CF0-Ten0-Gia0,
            tu_van_laptop(NhuCau, NganSach, YeuCauThem, Ten0, Gia0, CF0),
            DS),
    DS \= [],
    predsort(so_sanh_cf_giam_dan, DS, [CF-Ten-Gia|_]).

% ---> Hàm quan trọng nhất dành cho Python gọi <---
tu_van_top_k_giai_thich(NhuCau, NganSach, YeuCauThem, K, TopK, CanhBao) :-
    sieu_luat_xung_dot(NhuCau, NganSach, YeuCauThem, _, CanhBao),
    findall(CF0-Ten0-Gia0,
            tu_van_laptop(NhuCau, NganSach, YeuCauThem, Ten0, Gia0, CF0),
            DS),
    predsort(so_sanh_cf_giam_dan, DS, SortedDS),
    lay_k_phan_tu(K, SortedDS, TopK).

% ============================================================
% 9) TRUY VAN MAU DEMO
% ============================================================

% Copy/Paste dong nay vao terminal cua Prolog de chay thu:
% ?- tu_van_top_k_giai_thich(gaming, 35000000, [mong_nhe, thich_thuong_hieu('msi')], 3, Top3May, CanhBao).