// import { url } from "@kit.ArkTS"
//
//
// export  interface  SongItemType{
//   img:string
//   name:string
//   author:string
//   url:string
//   id:string
// }
//
//
//
// export  class GlobalMusic{
//
//   img:string=" "//音乐封面
//   name:string=" "//音乐名称
//   author:string=" "//作者
//   url:string=" "//当前播放链接
//   time:number=0//播放时间
//   duration:number=0//音乐的播放时长
//
//
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//    songs:SongItemType[] = [
//
//   {
//     img:'https://i.postimg.cc/xCQNxK2Q/jimeng-2025-05-25-207.jpghttps://i.postimg.cc/xCQNxK2Q/jimeng-2025-05-25-207.jpg',
//     name:'卡农钢琴曲',
//     author:'龙',
//     url:'https://www.myfreemp3.com.cn/?page=audioPage&type=netease&name=%E8%88%92%E7%BC%93%E9%92%A2%E7%90%B4%E6%9B%B2',
//     id:'0000'
//
//   },
//   {
//     img:'https://i.postimg.cc/xCQNxK2Q/jimeng-2025-05-25-207.jpg',
//     name:'稳稳的幸福钢琴曲',
//     author:'龙',
//     url:'https://www.myfreemp3.com.cn/?page=audioPage&type=netease&name=%E8%88%92%E7%BC%93%E9%92%A2%E7%90%B4%E6%9B%B2',
//     id:'0001'
//   },
//
//   {
//     img:'https://i.postimg.cc/xCQNxK2Q/jimeng-2025-05-25-207.jpg',
//     name:'舒缓钢琴曲',
//     author:'龙',
//     url:'https://www.myfreemp3.com.cn/?page=audioPage&type=netease&name=%E8%88%92%E7%BC%93%E9%92%A2%E7%90%B4%E6%9B%B2',
//     id:'0002'
//   },
// {
//   img:'https://i.postimg.cc/xCQNxK2Q/jimeng-2025-05-25-207.jpg',
//   name:'百代匠心铸炎黄',
//   author:'龙',
//   url:'https://female-amaranth-fosuk2jm3e.edgeone.app?eo_token=2ad3aae9ed3016030aacf05dfe1636a1&eo_time=1758087689',
//   id:'0003'
// }
//
// ]
//
// number2time(number:number){
//   if (number>60*1000){
//
//     const  s =Math.floor(number/1000%60)
//     const  m =Math.floor(number/1000/60)
//     const  second =s.toString().padStart(2,'0')
//     const  mitute =s.toString().padStart(2,'0')
//
//   }else {
//     const  s =Math.floor(number/1000%60)
//     const  second =s.toString().padStart(2,'0')
//     return '00:'+second
//   //
//   }
//
//
//
// }
//
