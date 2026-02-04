class MessageUtils {
  static String getPaymentReminderMessage(String name, String nis, String monthYear) {
    return """Assalamualaikum warohmatullahi wabarokatuh

    Sehubungan akan berakhirnya bulan $monthYear

    Kami hanya mengingatkan..!

    Menurut catatan bendahara lembaga kami, bahwa anak Bapak/Ibu:
    Nama: $name
    NIS: $nis

    belum melunasi SPP $monthYear

    Silahkan cek spp anak di aplikasi.

    Mohon kerjasamanya, tunggakan tersebut agar segera diselesaikan.

    Pembayaran bisa via transfer : Rek Bank BSI 7117245448 AN : Fahmi Ramdani

    Atas kerjasamanya, terima kasih

    #Mohon koreksi bila data kami salah""";
  }
}
