#!/usr/bin/env python3
"""
国土数値情報バス停留所GMLファイル（P11形式）をGeoJSON形式に変換するスクリプト。

使い方:
    python tools/convert_bus_stops.py P11-10_46-jgd-g.xml assets/bus_stops/miyazaki_bus_stops.json
"""

import sys
import json
import xml.etree.ElementTree as ET


# 国土数値情報P11の名前空間
NAMESPACES = {
    'gml': 'http://www.opengis.net/gml',
    'ksj': 'http://nlftp.mlit.go.jp/ksj/schemas/ksj-app',
    'xlink': 'http://www.w3.org/1999/xlink',
}


def parse_gml(input_path: str) -> list[dict]:
    """GMLファイルを解析してバス停のリストを返す。"""
    try:
        tree = ET.parse(input_path, parser=ET.XMLParser(encoding='shift_jis'))
    except Exception:
        tree = ET.parse(input_path)

    root = tree.getroot()
    features = []

    # BSP（バス停）要素を走査
    for bsp in root.iter():
        local = bsp.tag.split('}')[-1] if '}' in bsp.tag else bsp.tag
        if local not in ('BusStop', 'BSP'):
            continue

        # 座標: <gml:pos>緯度 経度</gml:pos>
        pos_elem = bsp.find('.//gml:pos', NAMESPACES)
        if pos_elem is None or not pos_elem.text:
            continue
        parts = pos_elem.text.strip().split()
        if len(parts) < 2:
            continue
        lat = float(parts[0])
        lng = float(parts[1])

        # バス停名
        name = ''
        for tag in ('ksj:BSN', 'BSN', 'P11_003'):
            elem = bsp.find(f'.//{tag}', NAMESPACES) or bsp.find(f'.//{tag}')
            if elem is not None and elem.text:
                name = elem.text.strip()
                break

        # 事業者名
        operator = ''
        for tag in ('ksj:OPN', 'OPN', 'P11_004'):
            elem = bsp.find(f'.//{tag}', NAMESPACES) or bsp.find(f'.//{tag}')
            if elem is not None and elem.text:
                operator = elem.text.strip()
                break

        features.append({
            'type': 'Feature',
            'geometry': {
                'type': 'Point',
                'coordinates': [lng, lat],
            },
            'properties': {
                'n': name,
                'o': operator,
            },
        })

    return features


def main():
    if len(sys.argv) != 3:
        print('使い方: python tools/convert_bus_stops.py <入力GMLファイル> <出力JSONファイル>')
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    print(f'読み込み中: {input_path}')
    features = parse_gml(input_path)
    print(f'{len(features)} 件のバス停を取得しました')

    geojson = {
        'type': 'FeatureCollection',
        'features': features,
    }

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(geojson, f, ensure_ascii=False, indent=2)

    print(f'書き出し完了: {output_path}')


if __name__ == '__main__':
    main()
