// import { media } from '@kit.MediaKit'
// import {SongItemType} from'./music'
// import { AppStorageV2 } from '@kit.ArkUI'
// import {GlobalMusic} from './music'
//
// class  AvPlayerManger{
//
// //播放器
//   player:media.AVPlayer|null=null
// //共享播放数据
//   currentSong: GlobalMusic = AppStorageV2.connect( GlobalMusic,'SONG_KEY',()=>new  GlobalMusic())!
//
//
//
//
//
//
//
//   //创建播放器+监听器的状态
//     async init(){
//       if ((!this.player)) {
//
//
//
//         this.player= await media.createAVPlayer()
//
//       }
//
//       this.player.on('stateChange',(state)=>{
//         if(state==='initialized'){
//           this.player?.prepare()
//         }else if (state==='prepared'){
//           this.player?.play()
//         }
//
//       })
//
//
//       //时间变化
//       this.player.on('durationUpdate',(duration)=>{
//         this.currentSong.duration=duration
//       })
//
//     }
//
// //播放歌曲
// singPlay (song:SongItemType){
//
//     this.player!.url=song.url
//     // this.currentSong.img=song.img
// }
// }
//
//
//   export const playerManger:AvPlayerManger =  new AvPlayerManger()