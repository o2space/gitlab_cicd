#!/bin/bash

#用法提示
usage() {
    echo "Usage:"
    echo "  qiyewechat_sendMsg_api.sh [-u USER] [-t TITLE] [-c CONTENT] [-d DETAIL] [-p PICTURE] [-l LINK] [-y TYPE]"
    echo "Description:"
    echo "    USER, 用户."
    echo "    TITLE, 标题."
    echo "    CONTENT, 内容."
    echo "    DETAIL, 细节."
    echo "    PICTURE, 图片."
    echo "    LINK, 链接."
    echo "    TYPE, 内容类型."
    exit -1
}


# 获取脚本执行时的选项
while getopts u:t:c:d:p:l:y: option
do
   case "${option}"  in
                u) USER=${OPTARG};;
                t) TITLE=${OPTARG};;
                c) CONTENT=${OPTARG};;
                d) DETAIL=${OPTARG};;
                p) PICTURE=${OPTARG};;
                l) LINK=${OPTARG};;
                y) TYPE=${OPTARG};;
                h) usage;;
                ?) usage;;
   esac
   echo $option
   echo $OPTARG

done

#gitlab用户 匹配 企业微信通讯录用户账号
function getQiyewechatUserId(){
  local str=(`cat ./user_table.txt | awk -F ' ' '{print $1}'`)
  local userid=""
  local params=$@
  for i in ${!str[@]}
  do
    arr=(${str[i]//:/ })
    
    if [ ${arr[0]} == ${params[0]} ]; then
      echo ${arr[1]}
    fi 
  done

  echo ${userid}
}

function getQiyewechatUserIds(){
  local params=$@
  local userids=""
  arr=(${params//,/ })
  for i in ${!arr[@]}
  do
    tmp_str=$(getQiyewechatUserId ${arr[i]})
    if [[ $i != 0 ]]; then
      tmp_str=\|${tmp_str}
    fi
    userids=${userids}${tmp_str}
  done
  echo ${userids}
}

userids=$(getQiyewechatUserIds $USER)
echo userids:${userids}
# exit 0

#api的相关参数
#企业id
corpid='ww93f2060b7af1b265'
#企业下创建应用id
agentId=1000002
corpsecret='kaoVjgw1Qi2lnvqjBJbbxAl3mTkYCKq7sk7eOZyFA7Y'



#RESTFUL API 接口相关参数
HOST=https://qyapi.weixin.qq.com


#获取token
wechat_api_token=${HOST}/cgi-bin/gettoken
#例子:
#GET:https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=""&corpsecret=""
#返回内容:
#{
#       "errcode":0
#       "errmsg": ok
#       "access_token":"",
#       "expires_in": 7200,
#}


#发送消息
wechat_api_sendText=${HOST}/cgi-bin/message/send
#例子:
#POST: https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=ACCESS_TOKEN
#文本消息:
#{
#   "touser" : "UserID1|UserID2|UserID3"
#   "toparty" : "PartyID1|PartyID2",
#   "totag" : "TagID1 | TagID2",
#   "msgtype" : "text",
#   "agentid" : 1,
#   "text" : {
#       "content" : "你的快递已到，请携带工卡前往邮件中心领取。\n出发前可查看<a href=\"http://work.weixin.qq.com\">邮件中心视频实况</a>，聪明避开排队。"
#   },
#   "safe":0,
#   "enable_id_trans": 0
#}
#
#文本卡片消息:
#{
#   "touser" : "UserID1|UserID2|UserID3",
#   "toparty" : "PartyID1 | PartyID2",
#   "totag" : "TagID1 | TagID2",
#   "msgtype" : "textcard",
#   "agentid" : 1,
#   "textcard" : {
#            "title" : "领奖通知",
#            "description" : "<div class=\"gray\">2016年9月26日</div> <div class=\"normal\">恭喜你抽中iPhone 7一台，领奖码：xxxx</div><div class=\"highlight\">请于2016年10月10日前联系行政同事领取</div>",
#            "url" : "URL",
#            "btntxt":"更多"
#    },
#   "enable_id_trans": 0
#}
#
#图文消息:
# {
#   "touser" : "UserID1|UserID2|UserID3",
#   "toparty" : "PartyID1 | PartyID2",
#   "totag" : "TagID1 | TagID2",
#   "msgtype" : "news",
#   "agentid" : 1,
#   "news" : {
#       "articles" : [
#           {
#               "title" : "中秋节礼品领取",
#               "description" : "今年中秋节公司有豪礼相送",
#               "url" : "URL",
#               "picurl" : "http://res.mail.qq.com/node/ww/wwopenmng/images/independent/doc/test_pic_msg1.png"
#           }
#        ]
#   },
#   "enable_id_trans": 0
# }

#返回内容:
#{
#   "errcode" : 0,
#   "errmsg" : "ok",
#   "invaliduser" : "userid1|userid2", // 不区分大小写，返回的列表都统一转为小写
#   "invalidparty" : "partyid1|partyid2",
#   "invalidtag": "tagid1|tagid2"
# }


# 获取token
function getAccessToken {
   token_url="${wechat_api_token}?corpid=${corpid}&corpsecret=${corpsecret}"
   curl -d "" -X GET $token_url > token.json
   token=$(cat token.json | python -c "import sys, json; print(json.load(sys.stdin)['access_token'])")
   echo $token
}

token=$(getAccessToken)
echo token:$token

send_content=""
  
if [ $TYPE -eq 1 ] 
  then
    send_content="{
      \"touser\":\"$userids\",
      \"agentid\":\"$agentId\",
      \"msgtype\":\"text\",
      \"text\":{\"content\":\"$CONTENT\"},
      \"safe\":0,
      \"enable_id_trans\":0
      }"
elif [ $TYPE -eq 2 ] 
  then
    send_content="{
      \"touser\":\"$userids\",
      \"agentid\":\"$agentId\",
      \"msgtype\":\"textcard\",
      \"textcard\":{
            \"title\":\"$TITLE\",
            \"description\":\"$DETAIL\",
            \"url\":\"$LINK\",
            \"btntxt\":\"更多\"
      },
      \"enable_id_trans\":0
    }"
elif [ $TYPE -eq 3 ] 
  then
   send_content="{
      \"touser\":\"$userids\",
      \"agentid\":\"$agentId\",
      \"msgtype\":\"news\",
      \"news\":{
          \"articles\":[{
              \"title\":\"$TITLE\",
              \"description\":\"$DETAIL\",
              \"url\":\"$LINK\",
              \"picurl\":\"$PICTURE\"
          }]
      },
    \"enable_id_trans\":0
    }"
fi


echo -e $send_content > "send_content.json"
send_url="${wechat_api_sendText}?access_token=${token}"
echo $send_url
curl  --write-out %{http_code} -d '@send_content.json' -X POST ${send_url} > sendResult.json

