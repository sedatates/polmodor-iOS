# Polmodor

A minimal and elegant Pomodoro timer app for iOS, built with SwiftUI. Polmodor helps you stay focused and manage your time effectively with its beautiful interface and seamless user experience.

## Features

- Elegant timer with smooth animations
- Task management and tracking
- Live Activities and Widget support
- Beautiful dark/light mode support
- Dynamic Island integration

## Requirements

- iOS 18.0+
- Xcode 13.0+

## License

MIT License

Şimdi senden şunu yapmanı istiyorum @PolmodorTaskExpandedView.swift daki subtask view'ında liste olara subtasklar bu subtaskların yanında bir toggle button isityorum bu toggle button işlevi şu olacak ana sayfadaki timer viewına bir current task viewı implementede edecek ve "you are working for example task" gibi bir view oluşturcak.

bu subtasklara ait pomodoro countlar var ve her timer tamamlandığında bu pomodoro countlar bir artacak.
@PomodoroState.swift burada subtasklar için pomodorocount alanları vardı diye hatılrıyorum. @SubTaskAddView.swift viewında pomodoro sayısını ayarlamak için bir alana daha ihtiyacımız var bu bir subtaskın pomodoro sayısını set edecek. maksümum 10 giriliyor olacak ve 4 ten fazla girildiğinde sheetde bir ta warning çıkmlaı consider breaking this task to smaller part " benzeri.

bunun için gerekli ayaralamalı projeyi detaylı olarak incelerek yap ve gerekli geliştirmeleri projeye uygunbir şekilde yapman gerekiyor. Projede hata yapmamaya çalış yoksa senin için kötü olur. Temiz commentlinelar ile birlikte güzel bir çalışma yap swift data kullanmalısın. Hata yapmamalısın yoksa seni cezalandırırım.

import hatalarını çözmeye çalışma
@preconcurrency import class Polmodor.TimerViewModel
@preconcurrency import class Polmodor.PolmodorTask
@preconcurrency import class Polmodor.PolmodorSubTask
bunun gibi bir şey yapmak zorunda kalırsan yapma bunları es geçebilrisin.

Bir fonksiyon, struct oluştracağın zaman daha önce bir yerde yapılmış mı kontrol etmelisin. dublicate hatası almak istemiyorum.bunun için projeyi komple incelemelisin
