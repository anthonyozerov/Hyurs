# Exernal imports:
from tkinter import *
from tkinter import ttk
from dateutil.relativedelta import relativedelta
import math, datetime, random

# Hyurs imports:
import hy
import graph as grapher
import report as reporter
from stats import hyx_opts_XgreaterHthan_signXtreelist as opts_to_treelist
import data, stats


# DATA AND GRAPHING INTEGRATION:
background_colour = "#ffffff"
graph_size = 500

def deg(rad):
    return rad * 180 / math.pi;

def filled_arc_fn(cx, cy, r1, r2, ang1, ang2, colour):
    angular_width = 359.999 if deg(ang2 - ang1) > 359.999 else deg(ang2 - ang1)
    # ^ otherwise the arc is not drawn if it spans 360 degrees
    return canvas.create_arc(cx - r2, cy - r2, cx + r2, cy + r2,
                             start = deg(ang1), extent = angular_width,
                             fill=colour, outline="black", width=1)

def filled_rect_fn(x1, y1, x2, y2, colour):
    return canvas.create_rectangle(x1, y1, x2, y2, fill=colour)

def line_fn(x1, y1, x2, y2):
    return canvas.create_line(x1, y1, x2, y2)

def angled_text_fn(x, y, angle, label):
    return canvas.create_text(x, y,
                              text = label, angle = deg(angle))

draw_slice = grapher.labelled_filled_arc_fn_gen(filled_arc_fn, angled_text_fn, background_colour)
draw_rect = grapher.labelled_filled_rect_fn_gen(filled_rect_fn, angled_text_fn, background_colour)
draw_line_lbl = grapher.labelled_line_fn_gen(line_fn, angled_text_fn)

def decode_ui_input():
    n = int(int_num.get())
    filtered_tags = special_tags.get()
    rule_in = False if include_btn.instate(["selected"]) else True
    level_str = tag_levels.get()
    start_level = 0
    end_level = 999 # if your tagging system has more levels, get help
    if level_str != "":
        start_level, end_level = map(int, level_str.split("-"))
    ts = data.dateparse_tz(start_ts.get())
    delta = None
    interval_str = interval.get()
    interval_type = interval_str[-1]
    if interval_type == "d":
        delta = relativedelta(days=int(interval_str[:-1]))
    elif interval_type == "m":
        delta = relativedelta(months=int(interval_str[:-1]))
    elif interval_type == "y":
        delta = relativedelta(years=int(interval_str[:-1]))
    else:
        print("Can't understand your time interval: " + interval_str)
        return
    end_ts = ts + delta * n
    return {"mapping": mapping_name.get(),
            "intervals": n,
            "special_tags": filtered_tags,
            "rule_in": rule_in,
            "start_level": start_level,
            "end_level": end_level,
            "start_ts": ts,
            "end_ts": end_ts,
            "timedelta": delta,
            "filepath": save_path.get()}

def graph(*args):
    seed = random.random() * 100
    input = decode_ui_input()
    x = 0
    clear_canvas()
    ts = input["start_ts"]
    delta = input["timedelta"]
    ts2 = input["start_ts"]
    max_val_sum = 0
    while ts2 < input["end_ts"]: # find the scale so we can size the flame chart
        treelist = opts_to_treelist(input["mapping"],
                                    str(ts2),
                                    str(ts2 + delta),
                                    input["rule_in"],
                                    input["special_tags"])
        sum = stats.tl_sum(treelist)
        if sum > max_val_sum:
            max_val_sum = sum
        ts2 += delta
    while ts < input["end_ts"]:
        if graph_type.get() == "Pie":
            grapher.make_pie_chart(opts_to_treelist(input["mapping"],
                                                    str(ts),
                                                    str(ts + delta),
                                                    input["rule_in"],
                                                    input["special_tags"]),
                                   input["start_level"],
                                   input["end_level"],
                                   draw_slice,
                                   grapher.gen_col_fn(seed),
                                   x + graph_size / 2, graph_size / 2,
                                   graph_size)
        else:
            grapher.make_flame_chart(opts_to_treelist(input["mapping"],
                                                    str(ts),
                                                    str(ts + delta),
                                                    input["rule_in"],
                                                    input["special_tags"]),
                                     input["start_level"],
                                     input["end_level"],
                                     draw_rect,
                                     grapher.gen_col_fn(seed),
                                     x + 30, 30,
                                     graph_size / max_val_sum,
                                     graph_size / 5)
            grapher.draw_scale(draw_line_lbl,
                               x + 20, 30,
                               graph_size / max_val_sum,
                               max_val_sum,
                               True)
        angled_text_fn(x + graph_size / 2, 10, 0,
                       str(ts.date()) + " - " + str((ts + delta).date()))
        x += graph_size
        ts += delta
    canvas["scrollregion"] = (0, 0, x, canvas_height)

def report(*args):
    input = decode_ui_input()
    start_ts = input["start_ts"]
    delta = input["timedelta"]
    start_times = [start_ts + i * delta for i in range(input["intervals"])]
    end_times = [ts + delta for ts in start_times]
    reporter.save_multi_report(input["mapping"],
                               list(map(str, start_times)),
                               list(map(str, end_times)),
                               input["filepath"])


# ------------------- #
#    USER INTERFACE   #
# (horror code ahead) #
# ------------------- #
root = Tk()
root.title("Hyurs")

input_width = 10

screen_width = root.winfo_screenwidth()
screen_height = root.winfo_screenheight()

# MAIN FRAMES
"""
root
    mainframe
        inputframe
            frameleft
            frameright
        outputframe
            graphsframe
"""

mainframe = ttk.Frame(root)
mainframe.grid(column=0, row=0, sticky=(N, W, E, S))
root.columnconfigure(0, weight=1)
root.rowconfigure(0, weight=1)

inputframe = ttk.Frame(mainframe)
inputframe.grid(column=0,row=0,sticky=(N, W, E, S))

outputframe = ttk.Frame(mainframe)
outputframe.grid(column=0,row=1,sticky=(N, W, E, S))

graphsframe = ttk.Frame(outputframe)
graphsframe.grid(column=0,row=0,sticky=(N,W,E,S))

# INPUT FRAMES

frameleft = ttk.Frame(inputframe, padding="3 3 12 12")
frameleft.grid(column=0, row=0, sticky=(N,W,E,S))

frameright = ttk.Frame(inputframe, padding="3 3 12 12")
frameright.grid(column=1, row=0, sticky=(N,W,E,S))

# LEFT FRAME

mapping_name = StringVar()
mapping_selector = ttk.Combobox(frameleft, textvariable=mapping_name)
mapping_selector.grid(column=2, row=0, sticky=(W, E))
ttk.Label(frameleft, text="Mapping:").grid(column=1, row=0, sticky=W)
ttk.Label(frameleft, text="(you chose these names when creating tags)").grid(column=3,row=0)
mapping_selector.state(["readonly"])
mapping_selector['values'] = data.mapping_names()
mapping_selector.current(0)

start_ts = StringVar()
start_ts_entry = ttk.Entry(frameleft, width=input_width, textvariable=start_ts)
start_ts_entry.grid(column=2, row=1, sticky=(W, E))
start_ts_entry.insert(0, "2021-01-01")
ttk.Label(frameleft, text="Start date:").grid(column=1, row=1, sticky=W)

interval = StringVar()
interval_entry = ttk.Entry(frameleft, width=input_width, textvariable=interval)
interval_entry.grid(column=2, row=2, sticky=(W, E))
interval_entry.insert(0, "1m")
ttk.Label(frameleft, text="Interval:").grid(column=1, row=2, sticky=W)
ttk.Label(frameleft, text="(end with d/m/y for days/months/years)").grid(column=3,row=2)

int_num = StringVar()
int_num_entry = ttk.Entry(frameleft, width=input_width, textvariable=int_num)
int_num_entry.grid(column=2, row=3, sticky=(W, E))
int_num_entry.insert(0, "3")
ttk.Label(frameleft, text="Number of intervals:").grid(column=1, row=3, sticky=W)

save_path = StringVar()
save_path_entry = ttk.Entry(frameleft, width=input_width, textvariable=save_path)
save_path_entry.grid(column=2, row=4, sticky=(W,E))
save_path_entry.insert(0, "out/report-" + str(datetime.datetime.now()))
ttk.Label(frameleft, text="Report path:").grid(column=1, row=4, sticky=W)
reportbtn = ttk.Button(frameleft, text='Generate report', command=report)
reportbtn.grid(column=2,row=5)


# RIGHT FRAME

ttk.Label(frameright, text="Graph type:").grid(column=1, row=1, sticky=(W,E))

graph_type = StringVar()
graph_type_select = ttk.Combobox(frameright, textvariable=graph_type)
graph_type_select.grid(column=2, row=1, sticky=(W,E))
graph_type_select.state(["readonly"])
graph_type_select['values'] = ("Pie", "Flame")
graph_type_select.current(0)

ttk.Label(frameright, text="Tag levels:").grid(column=1, row=2, sticky=W)

tag_levels = StringVar()
tag_levels_entry = ttk.Entry(frameright, width=input_width, textvariable=tag_levels)
tag_levels_entry.grid(column=2,row=2,sticky=(W,E))

ttk.Label(frameright, text="Tags:").grid(column=1, row=3, sticky=W)

special_tags = StringVar()
special_tags_entry = ttk.Entry(frameright, width=input_width, textvariable=special_tags)
special_tags_entry.grid(column=2,row=3,sticky=(W,E))

only_special_tags = StringVar()
exclude_btn = ttk.Radiobutton(frameright, text='rule in', variable=only_special_tags, value=False)
include_btn = ttk.Radiobutton(frameright, text='rule out', variable=only_special_tags, value=True)
only_special_tags.set(True)
exclude_btn.grid(column=3,row=3)
include_btn.grid(column=4,row=3)


# THE BUTTON

button = ttk.Button(inputframe, text='Graph', command=graph)
button.grid(column=1,row=1)


# CANVAS
canvas_width = screen_width-24
canvas_height = screen_height * 2/3
hbar = ttk.Scrollbar(graphsframe, orient="horizontal")
vbar = ttk.Scrollbar(graphsframe, orient="vertical")
canvas = Canvas(graphsframe, width=canvas_width, height=canvas_height, background=background_colour,
                scrollregion=(0,0,canvas_width,canvas_height),
                yscrollcommand=vbar.set, xscrollcommand=hbar.set)
hbar['command'] = canvas.xview
vbar['command'] = canvas.yview
canvas.grid(column=0, row=0, sticky=(N,W,E,S))
hbar.grid(column=0, row=1, sticky=(W,E))
vbar.grid(column=1, row=0, sticky=(N,S))

def clear_canvas():
    canvas.delete("all")

for child in mainframe.winfo_children():
    child.grid_configure(padx=5, pady=5)

root.mainloop()
