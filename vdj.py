import xml.etree.ElementTree as ET
from urllib.parse import quote
from pathlib import Path
tree = ET.parse('database.xml')
root = tree.getroot()


def vdj_to_dict(root: ET.Element):
    tracks = {}
    for i, song in enumerate(root):
        # if "Aarena" not in song.attrib["FilePath"]:
        #     continue
        # print(child.find("Tags").attrib)
        path = song.attrib["FilePath"]
        relpath = path.split("\\")[-1]
        filename = Path(relpath).stem
        file_kind = Path(relpath).suffix.split('.')[-1]
        file_size = song.attrib["FileSize"]

        tags = song.find("Tags")
        infos = song.find("Infos")
        scan = song.find("Scan")


        try:
            title = tags.attrib["Title"]
        except KeyError:
            title = filename

        try:
            artist = tags.attrib["Author"]
        except KeyError:
            artist = None

        try:
            album = tags.attrib["Album"]
        except KeyError:
            album = None

        try:
            year = tags.attrib["Year"]
        except KeyError:
            year = None

        length = str(round(float(infos.attrib["SongLength"]), 3))
        bitrate = infos.attrib["Bitrate"]
        playcount = infos.attrib["PlayCount"]

        tonality = scan.attrib["Key"]
        bpm = str(round(1 / float(scan.attrib["Bpm"]) * 60, 3))

        cues = []

        for poi in song.findall("Poi"):
            if poi.attrib["Type"] == "cue":
                try:
                    pos = str(round(float(poi.attrib["Pos"]), 3))
                    num = str(int(poi.attrib["Num"]) - 1)
                    cues.append({"pos": pos, "num": num})
                except KeyError:
                    pass

            elif poi.attrib["Type"] == "beatgrid":
                grid_start = str(round(float(poi.attrib["Pos"]), 6))
            


        # print(title)

        # print(path)
        # print(filename)
        # print(file_kind)
        # print(title)

        # print([path, relpath, filename, file_kind, title, length, bitrate, playcount, tonality, bpm])  
        # print(cues)  
        tracks[i] = {
            "file_info": {"path": path, "relpath": relpath, "filename": filename, "file_kind": file_kind, "file_size": file_size},
            "track_info": {"title": title, "artist": artist, "album": album, "year": year, "length": length, "bitrate": bitrate, "playcount": playcount, "bpm": bpm, "tonality": tonality},
            "cue_info": {"grid_start": grid_start, "cues": cues}
        }

    return tracks

def dict_to_rkbx(set_dict: dict, output_path: str):
    root = ET.Element("DJ_PLAYLISTS")
    root.attrib["Version"] = "1.0.0"

    product = ET.SubElement(root, "PRODUCT")
    product.attrib["Name"] = "groffrey converter"
    product.attrib["Version"] = "0.0.1"
    product.attrib["Company"] = "grof productions"

    track_count = len(set_dict)

    collection = ET.SubElement(root, "COLLECTION")
    collection.attrib["Entries"] = str(track_count)

    for track_id, track_dict in set_dict.items():
        track = ET.SubElement(collection, "TRACK")
        track.attrib["TrackID"] = str(track_id)
        track.attrib["Name"] = track_dict["track_info"]["title"]
        if track_dict["track_info"]["artist"]:
            track.attrib["Artist"] = track_dict["track_info"]["artist"]
        if track_dict["track_info"]["album"]:
            track.attrib["Album"] = track_dict["track_info"]["album"]
        track.attrib["Kind"] = track_dict["file_info"]["file_kind"]

        raw_path = track_dict["file_info"]["path"]
        safe_path = quote(raw_path)
        rkbx_path = f"file://localhost/{safe_path}"
        track.attrib["Location"] = rkbx_path
        track.attrib["Size"] = track_dict["file_info"]["file_size"]
        track.attrib["TotalTime"] = track_dict["track_info"]["length"]
        if track_dict["track_info"]["year"]:
            track.attrib["Year"] = track_dict["track_info"]["year"]
        track.attrib["Tonality"] = track_dict["track_info"]["tonality"]

        for cue_data in track_dict["cue_info"]["cues"]:
            cue = ET.SubElement(track, "POSITION_MARK")
            cue.attrib["Name"] = "cue"
            cue.attrib["Type"] = "0"
            cue.attrib["Start"] = cue_data["pos"]
            cue.attrib["Num"] = cue_data["num"]

            cue.attrib["Red"] = "40"
            cue.attrib["Green"] = "226"
            cue.attrib["Blue"] = "20"

        tempo = ET.SubElement(track, "TEMPO")
        tempo.attrib["Inizio"] = track_dict["cue_info"]["grid_start"]
        tempo.attrib["Bpm"] = track_dict["track_info"]["bpm"]

    playlists = ET.SubElement(root, "PLAYLISTS")

    node_root = ET.SubElement(playlists, "NODE")
    node_root.attrib["Type"] = "0"
    node_root.attrib["Name"] = "ROOT"
    node_root.attrib["Count"] = "1"

    node_playlist = ET.SubElement(node_root, "NODE")
    node_playlist.attrib["Name"] = input("Enter playlist name: ")
    node_playlist.attrib["Type"] = "1"
    node_playlist.attrib["KeyType"] = "0"
    node_playlist.attrib["Entries"] = str(track_count)

    for i in tracks.keys():
        track = ET.SubElement(node_playlist, "TRACK")
        track.attrib["Key"] = str(i)


        

    tree = ET.ElementTree(root)
    ET.indent(tree, space=" ", level=0)
    tree.write(output_path, "UTF-8")

    




tracks = vdj_to_dict(root)


dict_to_rkbx(tracks, "testout.xml")
