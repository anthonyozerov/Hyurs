from tkinter import *
from tkinter import ttk

root = Tk()
root.title("Hyurs")


def graph(*args):
    return 0


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

start_ts = StringVar()
start_ts_entry = ttk.Entry(frameleft, width=input_width, textvariable=start_ts)
start_ts_entry.grid(column=2, row=1, sticky=(W, E))
ttk.Label(frameleft, text="Start date:").grid(column=1, row=1, sticky=W)

interval = StringVar()
interval_entry = ttk.Entry(frameleft, width=input_width, textvariable=interval)
interval_entry.grid(column=2, row=2, sticky=(W, E))
ttk.Label(frameleft, text="Interval:").grid(column=1, row=2, sticky=W)
ttk.Label(frameleft, text="(end with d/m/y for days/months/years)").grid(column=3,row=2)

int_num = StringVar()
int_num_entry = ttk.Entry(frameleft, width=input_width, textvariable=int_num)
int_num_entry.grid(column=2, row=3, sticky=(W, E))
ttk.Label(frameleft, text="Number of intervals:").grid(column=1, row=3, sticky=W)


# RIGHT FRAME

ttk.Label(frameright, text="Graph type:").grid(column=1, row=1, sticky=(W,E))

graph_type = StringVar()
graph_type_select = ttk.Combobox(frameright, textvariable=graph_type)
graph_type_select.grid(column=2, row=1, sticky=(W,E))
graph_type_select.state(["readonly"])
graph_type_select['values'] = ("Pie", "Flame")

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
exclude_btn.grid(column=3,row=3)
include_btn.grid(column=4,row=3)


# THE BUTTON

button = ttk.Button(inputframe, text='Graph', command=graph)
button.grid(column=1,row=1)


# CANVAS

canvas = Canvas(graphsframe, width=screen_width-24, height=400, background='gray75')
canvas.create_text(200, 100, text="Your graphs will appear here")
canvas.create_line(0, 0, 200, 200)
canvas.grid(column=0,row=0)



for child in mainframe.winfo_children():
    child.grid_configure(padx=5, pady=5)

root.mainloop()
