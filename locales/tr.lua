local Translations = {
    error = {
        no_deposit = '$%{value} Depozito gerekli',
        cancelled = 'İptal Edildi',
        vehicle_not_correct = 'Bu ticari bir araç değil!',
        no_driver = 'Bunu yapmak için sürücü olmalısınız..',
        no_work_done = 'Henüz bir iş yapmadınız...',
        backdoors_not_open = 'The backdoors of the vehicle aren\'t open',
        get_out_vehicle = 'You need to step out of the vehicle to perform this action',
        too_far_from_trunk = 'You need to grab the boxes from the trunk of your vehicle',
        too_far_from_delivery = 'You need to be closer to the delivery point'
    },
    success = {
        paid_with_cash = '$%{value} Depozitoyu nakit öde',
        paid_with_bank = '$%{value} Depozitoyu bankadan öde',
        refund_to_cash = '$%{value} Depozitoyu cash ile öde',
        you_earned = '$%{value} kazandın',
        payslip_time = 'Bütün dükkanlara gittin. Maaş Zamanı!',
    },
    menu = {
        header = 'Mevcut Kamyonlar',
        close_menu = '⬅ Menüyü Kapat',
    },
    mission = {
        store_reached = 'Mağazaya ulaşıldı, [E] ile bagajdan bir kutu alın ve işaretli yere teslim edin',
        take_box = 'Bir kutu ürün al',
        deliver_box = 'Kutuyu teslim et',
        another_box = 'Başka bir kutu al',
        goto_next_point = 'Tüm ürünleri teslim ettiniz, sonraki noktaya ilerleyin',
        return_to_station = 'You Have Delivered All Products, Return to Station',
        job_completed = 'You Have Completed Your Route, Please Collect Your Pay Cheque'
    },
    info = {
        deliver_e = '~g~E~w~ - Ürünleri Teslim Et',
        deliver = 'Ürünleri Teslim Et',
    }
}

if GetConvar('qb_locale', 'en') == 'tr' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
