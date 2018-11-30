#!/bin/sh

############# オプション処理 #############

function usage {
cat <<_EOT_
$(basename ${0}) はタイムマシンのローカルスナップショットを削除します。

Description
  * [重要] このスクリプトは使用者の責任においてご利用ください。
  * MacOS でハードディスクの情報に表示される「パージ可能」な領域の多く
    を占めるローカルスナップショットを削除するためのツールです。
  * パージ可能なファイルはディスク領域が不足した際にシステムにより削除
    されるそうですが、空き容量を常に確保することで爽快感を得ることを
    目的として作成しました。

Usage:
    $(basename ${0}) -e

    ローカルスナップショットが存在する場合は、
        n個の タイムマシン ローカルスナップショットが見つかりました。
        これらを削除しますか？[y/n/l(ist)] "
    と表示されます。
    [ y : 削除開始, n : 削除せずに終了, l : 削除対象一覧表示 ]

Options:
    -e  execute
    -h  print this
    -v  print $(basename ${0}) version

_EOT_
    exit 1
}

function version {
cat <<_EOT_
$(basename ${0}) version 0.1.0
_EOT_
    exit 1
}

unknownOption=true
# option
while getopts ":ehv" OPT
do
  case $OPT in
      e ) unknownOption=false ;;
      v ) version ;;
      h ) usage ;;
  esac
done

if $unknownOption; then
    usage
fi

############# 本体 #############

# localsnapshot の末尾の配列
idarray=()

# idarray を表示する
function listup {
    for idstr in "${idarray[@]}"; do
        echo "${idstr}"
    done
    echo ""
}

# 削除の確認操作
function confirm {
    echo "これらを削除しますか？[y/n/l(ist)]"

    read answer

    case $answer in
        y)
            ;;
        l)
            listup
            confirm ;;
        n)  exit 0 ;;
        *)  confirm ;;
    esac
}

# ローカルスナップショットのリストを得る
result=`tmutil listlocalsnapshots /`
# 改行で分割
resultarray=(`echo $result | tr -s '\n' ' '`)
# 各行から削除に必要な ID を取り出す
for line in "${resultarray[@]}"; do
	subarray=(`echo $line | tr -s '.' ' '`)
    lastindex=`expr ${#subarray[@]} - 1`
	idarray+=(${subarray[$lastindex]})
done

# 見つかった削除対象の個数
filecount=${#idarray[*]}
if [ $filecount -eq 0 ]; then
    # 削除対象なし
	echo "タイムマシン ローカルスナップショットが見つかりませんでした。"
else
    # 削除確認
    echo "${filecount}個の タイムマシン ローカルスナップショットが見つかりました。"
    confirm

    # 削除実行
    echo "削除開始:"
    for idstr in "${idarray[@]}"; do
        tmutil deletelocalsnapshots ${idstr}
    done
    echo "${filecount}個のローカルスナップショットを削除しました。"
fi
